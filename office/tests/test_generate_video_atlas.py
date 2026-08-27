import importlib.util
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace


requests_stub = ModuleType("requests")
requests_stub.RequestException = type("RequestException", (Exception,), {})
previous_requests = sys.modules.get("requests")
sys.modules["requests"] = requests_stub

SCRIPT = (
    Path(__file__).parents[1]
    / "skills"
    / "generate-video"
    / "scripts"
    / "generate_video.py"
)
spec = importlib.util.spec_from_file_location("generate_video", SCRIPT)
generate_video = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generate_video)
if previous_requests is None:
    del sys.modules["requests"]
else:
    sys.modules["requests"] = previous_requests


def args(model="mini"):
    return SimpleNamespace(
        model_sel=model,
        ratio="16:9",
        duration=5,
        resolution="720p",
        watermark=False,
        audio=True,
        seed=7,
    )


def test_builds_text_to_video_payload():
    payload = generate_video.build_atlas_payload("test prompt", [], args())

    assert payload == {
        "model": "bytedance/seedance-2.0-mini/text-to-video",
        "prompt": "test prompt",
        "ratio": "16:9",
        "duration": 5,
        "resolution": "720p",
        "watermark": False,
        "generate_audio": True,
        "seed": 7,
    }


def test_switches_alias_to_image_to_video(tmp_path):
    frame = tmp_path / "frame.png"
    frame.write_bytes(b"png")

    payload = generate_video.build_atlas_payload(
        "animate",
        [(str(frame), "first_frame")],
        args("fast"),
    )

    assert payload["model"] == "bytedance/seedance-2.0-fast/image-to-video"
    assert payload["image"].startswith("data:image/png;base64,")


def test_generation_post_is_issued_once():
    class Response:
        status_code = 200
        text = ""

        def raise_for_status(self):
            pass

        def json(self):
            return {"code": 200, "data": {"id": "prediction-1"}}

    class Session:
        posts = 0

        def post(self, *unused_args, **unused_kwargs):
            self.posts += 1
            return Response()

    session = Session()
    task_id = generate_video.create_atlas_task(session, "https://example.test", {})

    assert task_id == "prediction-1"
    assert session.posts == 1


def test_poll_retries_get_timeout(monkeypatch):
    class Response:
        def raise_for_status(self):
            pass

        def json(self):
            return {"data": {"status": "completed", "outputs": ["https://example.test/video.mp4"]}}

    class Session:
        gets = 0

        def get(self, *unused_args, **unused_kwargs):
            self.gets += 1
            if self.gets == 1:
                raise generate_video.requests.RequestException("timeout")
            return Response()

    monkeypatch.setattr(generate_video, "POLL_INTERVAL", 0)
    monkeypatch.setattr(generate_video, "ATLAS_MAX_POLLS", 2)
    session = Session()

    result = generate_video.poll_atlas_task(session, "https://example.test", "prediction-1")

    assert result["status"] == "completed"
    assert session.gets == 2
