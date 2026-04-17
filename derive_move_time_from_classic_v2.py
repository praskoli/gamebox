import csv
import json
from pathlib import Path
from typing import Any, Dict, List, Tuple

INPUT_CLASSIC = Path("./assets/gamepacks/sort_puzzle/color_classic_journey_pack.json")
OPTIONAL_CLASSIC_REPORT = Path("./assets/gamepacks/sort_puzzle/color_classic_journey_report.csv")

OUTPUT_DIR = Path("./assets/gamepacks/sort_puzzle")
MOVE_OUTPUT = OUTPUT_DIR / "color_move_challenge_pack.json"
TIME_OUTPUT = OUTPUT_DIR / "color_time_challenge_pack.json"

def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)

def load_optional_depths(path: Path) -> Dict[int, int]:
    depths: Dict[int, int] = {}
    if not path.exists():
        return depths
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                level = int(row.get("level") or row.get("levelNumber") or 0)
                depth = int(row.get("depth") or row.get("solveDepth") or 0)
                if level > 0 and depth > 0:
                    depths[level] = depth
            except Exception:
                continue
    return depths

def deep_copy(obj: Any) -> Any:
    return json.loads(json.dumps(obj))

def expand_stack(pieces: List[Dict[str, Any]]) -> List[str]:
    out: List[str] = []
    for piece in pieces:
        out.extend([str(piece["groupKey"])] * int(piece["amount"]))
    return out

def board_stats(level: Dict[str, Any]) -> Dict[str, int]:
    containers = level.get("containers", [])
    stacks = [expand_stack(c.get("pieces", [])) for c in containers]
    empties = sum(1 for s in stacks if not s)
    mixed = sum(1 for s in stacks if s and len(set(s)) >= 2)
    colors = len({item for s in stacks for item in s})
    repeated_tops = {}
    for s in stacks:
        if s:
            repeated_tops[s[-1]] = repeated_tops.get(s[-1], 0) + 1
    top_clash = max(repeated_tops.values()) if repeated_tops else 0
    return {
        "empties": empties,
        "mixed": mixed,
        "colors": colors,
        "top_clash": top_clash,
        "containers": len(stacks),
    }

def complexity_index(level: Dict[str, Any]) -> int:
    return int(level.get("band", 1))

def heuristic_depth(level: Dict[str, Any]) -> int:
    stats = board_stats(level)
    band = complexity_index(level)
    return max(
        6,
        4 + band * 2 + stats["mixed"] * 2 + max(0, stats["colors"] - 3) + max(0, 2 - stats["empties"]) * 2,
    )

def label_to_move_buffer(label: str) -> int:
    if label in {"simple", "simple_high"}:
        return 9
    if label in {"medium", "medium_high", "medium_complex"}:
        return 7
    if label in {"complex", "complex_high", "advanced", "advanced_high"}:
        return 5
    if label in {"expert_entry", "expert", "expert_high", "expert_complex"}:
        return 4
    return 3

def label_to_time_window(label: str) -> Tuple[int, int]:
    if label in {"simple", "simple_high"}:
        return (70, 95)
    if label in {"medium", "medium_high", "medium_complex"}:
        return (52, 74)
    if label in {"complex", "complex_high", "advanced", "advanced_high"}:
        return (38, 58)
    if label in {"expert_entry", "expert", "expert_high", "expert_complex"}:
        return (28, 44)
    return (20, 34)

def stable_choice(low: int, high: int, level_number: int) -> int:
    span = max(1, high - low)
    return low + (level_number * 7) % (span + 1)

def move_rank(level: Dict[str, Any], exact_depths: Dict[int, int]) -> Tuple[int, int, int, int]:
    level_no = int(level["levelNumber"])
    depth = exact_depths.get(level_no) or heuristic_depth(level)
    stats = board_stats(level)
    profile = str(level.get("profile", ""))
    profile_score = {"BOTTLENECK": 0, "DECOY": 1, "SPRINT": 2}.get(profile, 3)
    return (-depth, profile_score, stats["empties"], -stats["mixed"])

def time_rank(level: Dict[str, Any], exact_depths: Dict[int, int]) -> Tuple[int, int, int, int]:
    level_no = int(level["levelNumber"])
    depth = exact_depths.get(level_no) or heuristic_depth(level)
    stats = board_stats(level)
    profile = str(level.get("profile", ""))
    profile_score = {"SPRINT": 0, "DECOY": 1, "BOTTLENECK": 2}.get(profile, 3)
    return (profile_score, stats["top_clash"], -stats["empties"], depth)

def split_by_band(levels: List[Dict[str, Any]]) -> Dict[int, List[Dict[str, Any]]]:
    bands: Dict[int, List[Dict[str, Any]]] = {}
    for lvl in levels:
        bands.setdefault(int(lvl.get("band", 1)), []).append(lvl)
    return bands

def weave_bands_for_move(levels: List[Dict[str, Any]], exact_depths: Dict[int, int]) -> List[Dict[str, Any]]:
    # Different order than Classic without inventing new boards.
    ordered = sorted(levels, key=lambda lvl: move_rank(lvl, exact_depths))
    by_band = split_by_band(ordered)
    out: List[Dict[str, Any]] = []
    for band in sorted(by_band.keys()):
        bucket = by_band[band]
        # Alternate from front and back for more variety.
        left, right = 0, len(bucket) - 1
        toggle = True
        while left <= right:
            if toggle:
                out.append(bucket[left]); left += 1
            else:
                out.append(bucket[right]); right -= 1
            toggle = not toggle
    return out

def weave_bands_for_time(levels: List[Dict[str, Any]], exact_depths: Dict[int, int]) -> List[Dict[str, Any]]:
    ordered = sorted(levels, key=lambda lvl: time_rank(lvl, exact_depths))
    by_band = split_by_band(ordered)
    # Interleave bands in waves so Time has a visibly different sequence.
    band_keys = sorted(by_band.keys())
    pointers = {b: 0 for b in band_keys}
    out: List[Dict[str, Any]] = []
    while len(out) < len(levels):
        progressed = False
        for b in band_keys:
            bucket = by_band[b]
            idx = pointers[b]
            if idx < len(bucket):
                out.append(bucket[idx])
                pointers[b] += 1
                progressed = True
        if not progressed:
            break
    return out

def reorder_containers(containers: List[Dict[str, Any]], seed: int, mode: str) -> List[Dict[str, Any]]:
    # Safe transformation: only container positions change, puzzle stays identical.
    items = deep_copy(containers)
    n = len(items)
    if n <= 1:
        return items

    if mode == "move":
        # Rotation + reverse on odd seeds.
        shift = seed % n
        rotated = items[shift:] + items[:shift]
        if seed % 2 == 1:
            rotated = list(reversed(rotated))
        return rotated

    # Time: pull empties forward and rotate remainder for faster visual scan.
    empties = [c for c in items if not c.get("pieces")]
    non_empty = [c for c in items if c.get("pieces")]
    if non_empty:
        shift = (seed * 3) % len(non_empty)
        non_empty = non_empty[shift:] + non_empty[:shift]
    return empties + non_empty

def derive_move_level(source: Dict[str, Any], new_level_number: int, exact_depths: Dict[int, int]) -> Dict[str, Any]:
    level = deep_copy(source)
    source_level_no = int(source["levelNumber"])
    depth = exact_depths.get(source_level_no) or heuristic_depth(source)
    label = str(source.get("complexityLabel", "medium"))

    move_limit = max(depth + label_to_move_buffer(label), depth + 3)

    level["world"] = "move_challenge"
    level["levelNumber"] = new_level_number
    level["difficulty"] = "hard" if depth > 30 else "medium" if depth > 18 else "easy"
    level["containers"] = reorder_containers(level.get("containers", []), source_level_no + new_level_number, "move")
    level.setdefault("config", {})
    level["config"]["moveLimit"] = move_limit
    level["config"]["timeLimitSeconds"] = None
    level["derivedFromClassicLevel"] = source_level_no
    level["officialModeKey"] = "move_challenge"
    return level

def derive_time_level(source: Dict[str, Any], new_level_number: int, exact_depths: Dict[int, int]) -> Dict[str, Any]:
    level = deep_copy(source)
    source_level_no = int(source["levelNumber"])
    depth = exact_depths.get(source_level_no) or heuristic_depth(source)
    label = str(source.get("complexityLabel", "medium"))

    low, high = label_to_time_window(label)
    low = max(15, low - max(0, depth - 20) // 5)
    high = max(low + 4, high - max(0, depth - 20) // 4)
    time_limit = stable_choice(low, high, new_level_number)

    level["world"] = "time_challenge"
    level["levelNumber"] = new_level_number
    level["difficulty"] = "hard" if depth > 30 else "medium" if depth > 18 else "easy"
    level["containers"] = reorder_containers(level.get("containers", []), source_level_no + new_level_number, "time")
    level.setdefault("config", {})
    level["config"]["moveLimit"] = None
    level["config"]["timeLimitSeconds"] = time_limit
    level["derivedFromClassicLevel"] = source_level_no
    level["officialModeKey"] = "time_challenge"
    return level

def build_world_pack(world: str, levels: List[Dict[str, Any]]) -> Dict[str, Any]:
    return {"world": world, "variant": "color", "levels": levels}

def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    classic_pack = load_json(INPUT_CLASSIC)
    classic_levels: List[Dict[str, Any]] = list(classic_pack.get("levels", []))
    if not classic_levels:
        raise RuntimeError(f"No levels found in {INPUT_CLASSIC}")

    exact_depths = load_optional_depths(OPTIONAL_CLASSIC_REPORT)

    move_source = weave_bands_for_move(classic_levels, exact_depths)
    time_source = weave_bands_for_time(classic_levels, exact_depths)

    move_levels = [derive_move_level(level, idx + 1, exact_depths) for idx, level in enumerate(move_source)]
    time_levels = [derive_time_level(level, idx + 1, exact_depths) for idx, level in enumerate(time_source)]

    with MOVE_OUTPUT.open("w", encoding="utf-8") as f:
        json.dump(build_world_pack("move_challenge", move_levels), f, indent=2, ensure_ascii=False)

    with TIME_OUTPUT.open("w", encoding="utf-8") as f:
        json.dump(build_world_pack("time_challenge", time_levels), f, indent=2, ensure_ascii=False)

    print("Done.")
    print(f"Classic source: {INPUT_CLASSIC}")
    print(f"Move output:   {MOVE_OUTPUT}")
    print(f"Time output:   {TIME_OUTPUT}")
    print(f"Levels reused: {len(classic_levels)}")
    print(f"Exact depths loaded from report: {len(exact_depths)}")
    print("This version reorders levels differently and reshuffles container positions safely.")

if __name__ == "__main__":
    main()
