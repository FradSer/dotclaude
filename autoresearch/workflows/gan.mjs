export const meta = {
  name: 'autoresearch-gan',
  description: 'GAN-style tournament: fan out candidate edits, evaluate (scorer/gate/rubric), judge, synthesize the best, re-evaluate, iterate to a target',
  phases: [
    { title: 'Baseline', detail: 'evaluate the unmodified artifact' },
    { title: 'Candidates', detail: 'fan out N variants in isolated worktrees' },
    { title: 'Judge', detail: 'rank survivors; mark graftable ideas' },
    { title: 'Synthesize', detail: 'combine winner + grafts, re-evaluate' },
  ],
}

// --- config (from gan-setup.sh JSON, passed verbatim as Workflow args) -------
const cfg = args || {}
const EDIT = cfg.edit
const OBJECTIVE = cfg.objective
const PROMPT = cfg.prompt || ''
const SCORE_CMD = cfg.score_cmd || null
const CHECK_CMD = cfg.check_cmd || null
const RUBRIC = cfg.rubric || null
const DIRECTION = cfg.direction === 'min' ? 'min' : 'max'
const TARGET = (typeof cfg.target_score === 'number') ? cfg.target_score : null
const MAX_ROUNDS = cfg.max_rounds > 0 ? cfg.max_rounds : 5
const N = cfg.candidates > 0 ? cfg.candidates : 4
const TRIAL_TIMEOUT = cfg.trial_timeout > 0 ? cfg.trial_timeout : 600
const READONLY = Array.isArray(cfg.readonly) ? cfg.readonly : []

const HAS_SCORE = !!SCORE_CMD
const HAS_GATE = !!CHECK_CMD
const HAS_RUBRIC = !!RUBRIC
// Evaluator mode: a numeric scorer ranks directly; else an LLM rubric ranks
// (grounded by the required gate/score anchor); else a bare gate just needs a
// passing variant. The gate, when present, is always a hard filter.
const MODE = HAS_SCORE ? 'numeric' : (HAS_RUBRIC ? 'rubric' : 'gate')

const DRY_LIMIT = 2
const ROUND_BUDGET_FLOOR = 60_000
const PANEL = 3 // independent rubric judges (adversarial grounding)

const ANGLES = [
  'a minimal, surgical change — the smallest edit that could plausibly help',
  'an aggressive restructuring — rethink the artifact, not just tweak it',
  'a different underlying approach/algorithm than the current best uses',
  'target the most likely weakness of the current best and fix exactly that',
  'combine two independent improvements into one coherent change',
  'simplify the current best while preserving what makes it good',
]

const isNum = (x) => typeof x === 'number' && Number.isFinite(x)
const better = (a, b) => !isNum(b) ? isNum(a) : (DIRECTION === 'min' ? a < b : a > b)
const targetReached = (s) => HAS_SCORE && TARGET !== null && isNum(s) && (DIRECTION === 'min' ? s <= TARGET : s >= TARGET)
const dirWord = DIRECTION === 'min' ? 'LOWER' : 'HIGHER'
const eligible = (c) => c && !c.crashed && (!HAS_GATE || c.gate_pass === true) && (!HAS_SCORE || isNum(c.score))

const READONLY_NOTE = READONLY.length
  ? `NEVER modify these read-only paths: ${READONLY.join(', ')}.`
  : 'There are no extra read-only paths.'

// Evaluation instructions shared by every candidate/baseline/synth agent.
const GATE_STEP = HAS_GATE
  ? `GATE (objective, run first): timeout ${TRIAL_TIMEOUT} sh -c '${CHECK_CMD}' — exit 0 => gate_pass=true, any non-zero/timeout => gate_pass=false. Never edit the gate or read-only paths to force a pass.`
  : `There is no gate; set gate_pass=true.`
const SCORE_STEP = HAS_SCORE
  ? `SCORE: timeout ${TRIAL_TIMEOUT} sh -c '${SCORE_CMD}' — the LAST stdout line MUST be one number => score. Timeout/missing/non-numeric => set score=null, crashed=true.`
  : `There is no numeric scorer; set score=null.`
const EVAL_STEP = `Evaluate your edit:\n   - ${GATE_STEP}\n   - ${SCORE_STEP}\n   Report content (the FULL new text of ${EDIT}), score, gate_pass, crashed, and a one-line description.`

const CANDIDATE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    content: { type: 'string', description: 'the FULL new text of the edited artifact' },
    description: { type: 'string', description: 'one line: what this change does' },
    score: { type: ['number', 'null'], description: 'scorer last line, or null' },
    gate_pass: { type: 'boolean', description: 'did the gate pass (true if no gate)' },
    crashed: { type: 'boolean' },
  },
  required: ['content', 'description', 'score', 'gate_pass', 'crashed'],
}
const JUDGE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    winner_index: { type: 'integer' },
    graft_notes: { type: 'string', description: 'concrete ideas from the other options worth grafting into the winner' },
    ranking: { type: 'array', items: { type: 'integer' } },
  },
  required: ['winner_index', 'graft_notes'],
}

function candidatePrompt(best, i, round) {
  return `You are candidate ${i + 1} of ${N} in round ${round} of a GAN-style optimization tournament.

## Research goal
${PROMPT}

## Objective
${OBJECTIVE}${HAS_SCORE ? `\nOptimization direction: ${DIRECTION} (a ${dirWord} score is better).` : ''}${HAS_RUBRIC ? `\nQuality rubric the judges will apply:\n${RUBRIC}` : ''}

## Current best artifact${isNum(best.score) ? ` (score ${best.score})` : ''}
The single editable file is ${EDIT}. Its current best content:
<<<CURRENT_BEST
${best.content}
CURRENT_BEST

## Your task
1. Start from the current best. Make ONE distinct improvement, exploring: ${ANGLES[i % ANGLES.length]}.
2. Write your full variant to ${EDIT} (overwrite). Modify ONLY ${EDIT}. ${READONLY_NOTE}
3. ${EVAL_STEP}

You are in an isolated worktree — your edit and evaluation do not affect anyone else.`
}

function baselinePrompt() {
  return `Establish the GAN baseline. The single editable file is ${EDIT}.

Objective: ${OBJECTIVE}

1. Read ${EDIT} and keep its current content unchanged.
2. ${EVAL_STEP}
Return content = the exact current text of ${EDIT}, plus score, gate_pass, crashed, description="baseline".`
}

function synthPrompt(winner, others, graftNotes, round) {
  const otherBlocks = others.map((c, i) =>
    `### Source ${i}${isNum(c.score) ? ` (score ${c.score})` : ''} — ${c.description}\n<<<CONTENT\n${c.content}\nCONTENT`).join('\n\n')
  return `Round ${round} synthesis. Produce ONE combined artifact that beats every candidate.

## Objective
${OBJECTIVE}${HAS_SCORE ? `\nDirection: ${DIRECTION} (${dirWord} is better).` : ''}${HAS_RUBRIC ? `\nRubric:\n${RUBRIC}` : ''}

## Winner (start from this)
<<<WINNER
${winner.content}
WINNER

## Promising ideas to graft in
${graftNotes || '(combine the strongest elements of the sources below)'}

## Runner-up sources
${otherBlocks || '(none)'}

## Your task
1. Start from the winner. Graft in the promising ideas, resolving conflicts into a coherent result.
2. Write it to ${EDIT} (overwrite). Modify ONLY ${EDIT}. ${READONLY_NOTE}
3. ${EVAL_STEP}

You are in an isolated worktree. Synthesis only wins on a real, re-measured result — not on plausibility.`
}

// Rank a list of {content, description, score?} against the rubric with an
// independent panel; majority vote on the winner, concatenated graft notes.
async function rubricRank(items, kind, round) {
  const blocks = items.map((c, i) =>
    `### Option ${i}${isNum(c.score) ? ` (score ${c.score})` : ''} — ${c.description}\n<<<CONTENT\n${c.content}\nCONTENT`).join('\n\n')
  const votes = await parallel(Array.from({ length: PANEL }, (_, k) => () =>
    agent(`You are judge ${k + 1} of a ${PANEL}-judge panel, round ${round}. Rank these options against the RUBRIC. Judge ONLY on the rubric; be strict and independent.

## Rubric
${RUBRIC}

## Objective
${OBJECTIVE}

${blocks}

Return winner_index (the option that best satisfies the rubric), graft_notes (concrete ideas from the OTHER options worth combining into the winner), and ranking (indices best-to-worst).`,
      { schema: JUDGE_SCHEMA, label: `r${round}-${kind}${k + 1}`, phase: `Round ${round}: judge` })))
  const valid = votes.filter((v) => v && Number.isInteger(v.winner_index) && items[v.winner_index])
  if (!valid.length) return { winnerIndex: 0, graftNotes: '' }
  const tally = {}
  for (const v of valid) tally[v.winner_index] = (tally[v.winner_index] || 0) + 1
  let winnerIndex = valid[0].winner_index, bestCount = -1
  for (const idx of Object.keys(tally)) if (tally[idx] > bestCount) { bestCount = tally[idx]; winnerIndex = +idx }
  const graftNotes = valid.map((v) => v.graft_notes).filter(Boolean).join(' | ')
  return { winnerIndex, graftNotes }
}

// Numeric mode: winner is already the top score; one judge supplies graft notes.
async function graftNotesFor(cands, round) {
  const blocks = cands.map((c, i) => `### Candidate ${i} (score ${c.score}) — ${c.description}`).join('\n')
  const j = await agent(`Round ${round}: candidates ranked by score (${dirWord} better):\n${blocks}\n\nThe top candidate is index 0. Return winner_index=0 and graft_notes: concrete ideas from the other candidates worth grafting into the winner.`,
    { schema: JUDGE_SCHEMA, label: `r${round}-graft`, phase: `Round ${round}: judge` })
  return (j && j.graft_notes) || ''
}

// --- baseline ----------------------------------------------------------------
phase('Baseline')
const baseline = await agent(baselinePrompt(), { schema: CANDIDATE_SCHEMA, label: 'baseline', phase: 'Baseline' })
if (!baseline || typeof baseline.content !== 'string') {
  log('GAN: baseline agent returned no artifact content — aborting.')
  return { error: 'baseline failed', rounds: 0 }
}
let best = {
  content: baseline.content,
  description: 'baseline',
  score: (isNum(baseline.score) && !baseline.crashed) ? baseline.score : null,
  gate_pass: HAS_GATE ? (baseline.gate_pass === true) : true,
}
const baselineScore = best.score
const history = [{ round: 0, kind: 'baseline', score: best.score, gate_pass: best.gate_pass }]
log(`baseline: ${MODE} mode | score=${isNum(best.score) ? best.score : 'n/a'} gate=${HAS_GATE ? best.gate_pass : 'n/a'}${TARGET !== null ? ` | target ${TARGET}` : ''}`)

// gate-only: a passing baseline already satisfies the goal.
let targetMet = MODE === 'gate' ? best.gate_pass : targetReached(best.score)

// --- tournament loop ---------------------------------------------------------
let dry = 0
let round = 0
while (
  round < MAX_ROUNDS && !targetMet && dry < DRY_LIMIT &&
  (!budget.total || budget.remaining() > ROUND_BUDGET_FLOOR)
) {
  round++
  phase(`Round ${round}: candidates`)
  const snapshot = best
  const raw = await parallel(Array.from({ length: N }, (_, i) => () =>
    agent(candidatePrompt(snapshot, i, round), {
      schema: CANDIDATE_SCHEMA, isolation: 'worktree',
      label: `r${round}-cand${i + 1}`, phase: `Round ${round}: candidates`,
    })))
  const cands = raw.filter(eligible)
  log(`round ${round}: ${cands.length}/${N} eligible candidates`)
  if (cands.length === 0) { dry++; history.push({ round, kind: 'candidates', note: 'none eligible' }); continue }

  let improved = false

  if (MODE === 'gate') {
    // Goal is a passing variant; the gate already filtered, so any survivor wins.
    best = { content: cands[0].content, description: cands[0].description, score: null, gate_pass: true }
    improved = true
    targetMet = true
  } else if (MODE === 'numeric') {
    cands.sort((a, b) => (DIRECTION === 'min' ? a.score - b.score : b.score - a.score))
    let roundBest = cands[0]
    if (cands.length > 1) {
      const graftNotes = await (HAS_RUBRIC
        ? rubricRank(cands, 'judge', round).then((r) => r.graftNotes)
        : graftNotesFor(cands, round))
      phase(`Round ${round}: synthesize`)
      const synth = await agent(synthPrompt(cands[0], cands.slice(1, 4), graftNotes, round),
        { schema: CANDIDATE_SCHEMA, isolation: 'worktree', label: `r${round}-synth`, phase: `Round ${round}: synthesize` })
      if (eligible(synth) && better(synth.score, roundBest.score)) roundBest = synth
      history.push({ round, kind: 'synthesis', score: eligible(synth) ? synth.score : null })
    }
    if (better(roundBest.score, best.score)) { best = { ...roundBest, gate_pass: HAS_GATE ? true : true }; improved = true }
    targetMet = targetReached(best.score)
  } else { // rubric
    phase(`Round ${round}: judge`)
    const ranked = await rubricRank(cands, 'judge', round)
    const winner = cands[ranked.winnerIndex] || cands[0]
    const others = cands.filter((c) => c !== winner).slice(0, 3)
    phase(`Round ${round}: synthesize`)
    const synth = await agent(synthPrompt(winner, others, ranked.graftNotes, round),
      { schema: CANDIDATE_SCHEMA, isolation: 'worktree', label: `r${round}-synth`, phase: `Round ${round}: synthesize` })
    // Final ranking carries the current best in as a contestant for cross-round
    // comparison (no stable numeric scale, so let the panel compare directly).
    const finalists = [{ content: best.content, description: 'current best (carried over)', score: null }, ...cands]
    if (eligible(synth)) finalists.push({ content: synth.content, description: 'synthesis', score: null })
    const final = await rubricRank(finalists, 'final', round)
    if (final.winnerIndex !== 0) {
      const w = finalists[final.winnerIndex]
      best = { content: w.content, description: w.description, score: null, gate_pass: HAS_GATE ? true : true }
      improved = true
    }
    history.push({ round, kind: 'rubric-round', improved })
  }

  if (improved) { dry = 0; log(`round ${round}: NEW BEST — ${best.description}${isNum(best.score) ? ` (score ${best.score})` : ''}`) }
  else { dry++; log(`round ${round}: no improvement`) }
  history.push({ round, kind: 'round-best', score: best.score, improved })
}

const stop = targetMet ? (MODE === 'gate' ? 'gate satisfied' : 'target reached')
  : round >= MAX_ROUNDS ? 'max rounds'
  : dry >= DRY_LIMIT ? `${DRY_LIMIT} dry rounds`
  : 'budget floor'
log(`GAN done (${stop}) over ${round} round(s)`)

return {
  mode: MODE,
  best_score: best.score,
  best_content: best.content,
  best_description: best.description,
  best_gate_pass: best.gate_pass,
  baseline_score: baselineScore,
  target_score: TARGET,
  target_reached: targetMet,
  rounds: round,
  stop_reason: stop,
  history,
}
