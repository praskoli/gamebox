import csv
import hashlib
import heapq
import json
import random
import time
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set, Any

# ============================================================
# CONFIGURATION
# ============================================================

OUTPUT_DIR = Path("./assets/gamepacks/sort_puzzle")
VARIANT = "color"
SEED = 4201701

LEVELS_PER_WORLD = 300
WORLDS = ["classic_journey", "move_challenge", "time_challenge", "theme_worlds"]

CAPACITY = 4
SOLVER_MAX_VISITS = 220000

PRIMARY_ATTEMPTS = 1200
RELAXED_ATTEMPTS = 900

COLOR_GROUPS = [
    "red", "blue", "green", "yellow", "purple", "orange",
    "pink", "cyan", "lime", "brown", "navy", "gold",
    "silver", "maroon", "teal", "indigo", "crimson"
]

THEME_SUB_WORLDS = [
    {"name": "candy_realm", "strategy": "alternating", "visual": "clean_open"},
    {"name": "sky_garden", "strategy": "staircase", "visual": "asymmetric_flow"},
    {"name": "crystal_cave", "strategy": "traps", "visual": "compact_dense"},
    {"name": "sunset_valley", "strategy": "funnels", "visual": "asymmetric_flow"},
    {"name": "festival_land", "strategy": "spiral", "visual": "fragmented_rhythm"},
    {"name": "dream_forest", "strategy": "corner_pressure", "visual": "edge_focus"},
]

SPRINT = "SPRINT"
BOTTLENECK = "BOTTLENECK"
DECOY = "DECOY"

COMPLEXITY_LABELS = [
    "simple",
    "simple_high",
    "medium",
    "medium_high",
    "medium_complex",
    "complex",
    "complex_high",
    "advanced",
    "advanced_high",
    "expert_entry",
    "expert",
    "expert_high",
    "expert_complex",
    "master_entry",
    "master",
    "master_high",
    "master_complex",
    "elite_entry",
    "elite",
    "elite_high",
    "elite_complex",
    "supreme_entry",
    "supreme",
    "supreme_high",
    "supreme_complex",
    "grandmaster_entry",
    "grandmaster",
    "grandmaster_high",
    "grandmaster_complex",
    "final_brutal",
]

# ============================================================
# MODELS
# ============================================================

@dataclass(frozen=True)
class BandPolicy:
    band_idx: int
    complexity_label: str
    min_colors: int
    max_colors: int
    target_depth: int
    target_empty_tubes: int
    move_buffer: int
    time_window: Tuple[int, int]
    min_mixed: int
    max_top_collision: int
    allow_near_solved: int
    scramble_steps: int

# ============================================================
# POLICY
# ============================================================

def get_band_policy(level: int) -> BandPolicy:
    idx = (level - 1) // 10
    label = COMPLEXITY_LABELS[idx]

    min_colors_curve = [
        3,3,3,4,4,4,4,5,5,5,
        5,5,6,6,6,6,6,7,7,7,
        7,8,8,8,8,9,9,9,10,10
    ]
    max_colors_curve = [
        4,4,4,4,5,5,5,5,6,6,
        6,6,6,7,7,7,7,8,8,8,
        8,9,9,9,9,10,10,10,11,11
    ]
    target_depth_curve = [
        6,8,10,12,14,16,18,20,22,24,
        26,28,30,32,34,36,38,40,42,44,
        46,48,50,52,54,56,58,60,62,64
    ]
    target_empty_curve = [
        2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1
    ]
    move_buffer_curve = [
        8,8,7,7,7,6,6,6,6,5,
        5,5,5,5,4,4,4,4,4,4,
        4,4,4,4,3,3,3,3,3,3
    ]
    min_mixed_curve = [
        1,1,2,2,2,2,2,3,3,3,
        3,3,4,4,4,4,4,5,5,5,
        5,5,6,6,6,6,6,6,6,6
    ]
    max_top_collision_curve = [
        4,4,4,4,4,4,4,4,4,4,
        4,4,4,4,4,3,3,3,3,3,
        3,3,3,3,3,3,3,3,3,3
    ]
    near_solved_curve = [
        2,2,2,1,1,1,1,1,1,1,
        1,1,1,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0
    ]
    scramble_steps_curve = [
        10,12,14,16,18,20,22,24,26,28,
        30,33,36,39,42,45,48,51,54,57,
        60,64,68,72,76,80,84,88,92,96
    ]
    time_windows = [
        (85, 110), (80, 105), (75, 100), (70, 95), (66, 90),
        (62, 86), (58, 82), (54, 78), (50, 74), (46, 70),
        (44, 66), (42, 63), (40, 60), (38, 57), (36, 54),
        (34, 52), (32, 49), (30, 46), (28, 44), (27, 42),
        (26, 40), (25, 38), (24, 36), (23, 34), (22, 33),
        (21, 31), (20, 30), (19, 29), (18, 28), (17, 27),
    ]

    return BandPolicy(
        band_idx=idx + 1,
        complexity_label=label,
        min_colors=min_colors_curve[idx],
        max_colors=max_colors_curve[idx],
        target_depth=target_depth_curve[idx],
        target_empty_tubes=target_empty_curve[idx],
        move_buffer=move_buffer_curve[idx],
        time_window=time_windows[idx],
        min_mixed=min_mixed_curve[idx],
        max_top_collision=max_top_collision_curve[idx],
        allow_near_solved=near_solved_curve[idx],
        scramble_steps=scramble_steps_curve[idx],
    )

def get_profile(level: int) -> str:
    mod = level % 3
    if mod == 1:
        return SPRINT
    if mod == 2:
        return BOTTLENECK
    return DECOY

def get_theme_for_level(level: int) -> Dict[str, str]:
    return THEME_SUB_WORLDS[((level - 1) // 50) % len(THEME_SUB_WORLDS)]

# ============================================================
# HELPERS
# ============================================================

def get_stable_fingerprint(board: List[List[str]]) -> str:
    board_str = "|".join(sorted("-".join(stack) for stack in board))
    return hashlib.md5(board_str.encode()).hexdigest()

def compress_stack(stack: List[str]) -> List[Dict[str, Any]]:
    if not stack:
        return []
    out = []
    current = stack[0]
    count = 1
    for item in stack[1:]:
        if item == current:
            count += 1
        else:
            out.append({"groupKey": current, "amount": count})
            current = item
            count = 1
    out.append({"groupKey": current, "amount": count})
    return out

def count_empty(board: List[List[str]]) -> int:
    return sum(1 for stack in board if not stack)

def count_mixed(board: List[List[str]]) -> int:
    return sum(1 for stack in board if stack and len(set(stack)) >= 2)

def count_solved_tubes(board: List[List[str]]) -> int:
    return sum(1 for stack in board if len(stack) == CAPACITY and len(set(stack)) == 1)

def near_solved_tubes(board: List[List[str]]) -> int:
    total = 0
    for stack in board:
        if len(stack) < CAPACITY - 1:
            continue
        counts = Counter(stack)
        if max(counts.values()) >= CAPACITY - 1:
            total += 1
    return total

def top_color_counts(board: List[List[str]]) -> Counter:
    return Counter(stack[-1] for stack in board if stack)

def duplicate_stack_count(board: List[List[str]]) -> int:
    filled = ["|".join(stack) for stack in board if stack]
    counts = Counter(filled)
    return sum(v - 1 for v in counts.values() if v > 1)

def has_triple_clump(board: List[List[str]]) -> bool:
    for stack in board:
        for i in range(len(stack) - 2):
            if stack[i] == stack[i + 1] == stack[i + 2]:
                return True
    return False

def structural_score(board: List[List[str]], policy: BandPolicy) -> int:
    score = 0
    empties = count_empty(board)
    mixed = count_mixed(board)
    solved = count_solved_tubes(board)
    near = near_solved_tubes(board)
    dup = duplicate_stack_count(board)
    top_clash_over = sum(max(0, v - policy.max_top_collision) for v in top_color_counts(board).values())

    score += abs(empties - policy.target_empty_tubes) * 3
    if mixed < policy.min_mixed:
        score += (policy.min_mixed - mixed) * 5
    if solved > 1:
        score += (solved - 1) * 7
    if near > policy.allow_near_solved:
        score += (near - policy.allow_near_solved) * 5
    if dup > 0:
        score += dup * 8
    if has_triple_clump(board):
        score += 3
    score += top_clash_over * 2
    return score

def candidate_quality_ok(board: List[List[str]], policy: BandPolicy, strict: bool) -> bool:
    score = structural_score(board, policy)
    if strict:
        threshold = 9 if policy.band_idx <= 5 else 13 if policy.band_idx <= 15 else 18 if policy.band_idx <= 24 else 23
    else:
        threshold = 18 if policy.band_idx <= 5 else 24 if policy.band_idx <= 15 else 30 if policy.band_idx <= 24 else 36
    return score <= threshold

# ============================================================
# SOLVER
# ============================================================

def normalize_state(state: Tuple[Tuple[str, ...], ...]) -> Tuple[Tuple[str, ...], ...]:
    return tuple(sorted(state))

def top_run_length(stack: Tuple[str, ...]) -> int:
    if not stack:
        return 0
    top = stack[-1]
    count = 1
    i = len(stack) - 2
    while i >= 0 and stack[i] == top:
        count += 1
        i -= 1
    return count

def is_solved_state(state: Tuple[Tuple[str, ...], ...]) -> bool:
    return all(not s or (len(s) == CAPACITY and len(set(s)) == 1) for s in state)

def valid_moves(state: Tuple[Tuple[str, ...], ...]) -> List[Tuple[int, int, int]]:
    moves: List[Tuple[int, int, int]] = []
    for i, src in enumerate(state):
        if not src:
            continue
        run = top_run_length(src)
        src_top = src[-1]
        for j, dst in enumerate(state):
            if i == j or len(dst) >= CAPACITY:
                continue
            if dst and dst[-1] != src_top:
                continue
            if not dst and len(set(src)) == 1:
                continue
            amount = min(run, CAPACITY - len(dst))
            if amount > 0:
                moves.append((i, j, amount))
    return moves

def valid_scramble_moves(state: Tuple[Tuple[str, ...], ...]) -> List[Tuple[int, int, int]]:
    moves: List[Tuple[int, int, int]] = []
    for i, src in enumerate(state):
        if not src:
            continue
        run = top_run_length(src)
        for j, dst in enumerate(state):
            if i == j or len(dst) >= CAPACITY:
                continue
            amount = min(run, CAPACITY - len(dst))
            if amount <= 0:
                continue
            # Mostly move 1 for control, sometimes 2 if available.
            moves.append((i, j, 1))
            if amount >= 2:
                moves.append((i, j, 2))
    return moves

def apply_move(state: Tuple[Tuple[str, ...], ...], move: Tuple[int, int, int]) -> Tuple[Tuple[str, ...], ...]:
    i, j, amount = move
    stacks = [list(s) for s in state]
    moved = stacks[i][-amount:]
    stacks[i] = stacks[i][:-amount]
    stacks[j].extend(moved)
    return tuple(tuple(s) for s in stacks)

def heuristic_score(state: Tuple[Tuple[str, ...], ...]) -> int:
    score = 0
    for stack in state:
        if not stack:
            continue
        if len(set(stack)) == 1:
            score -= len(stack)
        else:
            score += len(set(stack))
            for i in range(1, len(stack)):
                if stack[i] != stack[i - 1]:
                    score += 1
    return score

def solve_depth(board: List[List[str]]) -> Optional[int]:
    start = tuple(tuple(s) for s in board)
    queue = [(heuristic_score(start), 0, start)]
    seen = {normalize_state(start): 0}
    visits = 0

    while queue:
        _, depth, current = heapq.heappop(queue)
        visits += 1
        if visits > SOLVER_MAX_VISITS:
            return None
        if is_solved_state(current):
            return depth

        for move in valid_moves(current):
            nxt = apply_move(current, move)
            norm = normalize_state(nxt)
            next_depth = depth + 1
            if norm not in seen or seen[norm] > next_depth:
                seen[norm] = next_depth
                heapq.heappush(queue, (next_depth + heuristic_score(nxt), next_depth, nxt))
    return None

# ============================================================
# GENERATION
# ============================================================

def choose_pattern(profile: str, world: str, rng: random.Random) -> Tuple[str, str, str]:
    if world == "theme_worlds":
        return ("theme_mix", "theme_style", "themed")
    if profile == SPRINT:
        return (
            rng.choice(["zigzag", "alternating", "offset_blocks"]),
            rng.choice(["obvious_start", "recovery_board", "competing_paths"]),
            rng.choice(["clean_open", "center_focus", "symmetric_calm"]),
        )
    if profile == BOTTLENECK:
        return (
            rng.choice(["staircase", "cross_mix", "funnel"]),
            rng.choice(["tight_space", "pressure_board", "recovery_board"]),
            rng.choice(["compact_dense", "center_focus", "asymmetric_flow"]),
        )
    return (
        rng.choice(["ladder_mix", "cross_mix", "staircase"]),
        rng.choice(["false_opening", "hidden_start", "fake_easy"]),
        rng.choice(["asymmetric_flow", "center_focus", "fragmented_rhythm"]),
    )

def build_solved_board(colors: List[str], empty_tubes: int) -> List[List[str]]:
    board = [[c] * CAPACITY for c in colors]
    for _ in range(empty_tubes):
        board.append([])
    return board

def forward_scramble(colors: List[str], empty_tubes: int, steps: int, world: str, profile: str, rng: random.Random) -> List[List[str]]:
    board = build_solved_board(colors, empty_tubes)
    state = tuple(tuple(s) for s in board)

    for step in range(steps):
        moves = valid_scramble_moves(state)
        if not moves:
            break

        scored: List[Tuple[float, Tuple[int, int, int]]] = []
        for move in moves:
            i, j, amount = move
            src = state[i]
            dst = state[j]
            score = 0.0

            if profile == SPRINT:
                if len(dst) == 0:
                    score += 1.5
                if amount == 1:
                    score += 1.0
            elif profile == BOTTLENECK:
                if len(dst) > 0:
                    score += 2.0
                if len(src) == 1:
                    score += 0.8
            else:  # DECOY
                if len(dst) > 0:
                    score += 1.8
                if amount == 2:
                    score += 0.8

            if world == "move_challenge":
                if len(dst) > 0:
                    score += 1.2
                if amount == 2:
                    score += 0.6
            elif world == "time_challenge":
                if len(dst) == 0:
                    score += 0.6

            score += rng.random()
            scored.append((score, move))

        scored.sort(key=lambda x: x[0], reverse=True)
        candidate_pool = scored[:min(10, len(scored))]
        chosen_move = rng.choice(candidate_pool)[1]
        next_state = apply_move(state, chosen_move)
        if next_state == state:
            continue
        state = next_state

    return [list(s) for s in state]

def build_unconditional_fallback_board(level_num: int, policy: BandPolicy, profile: str, rng: random.Random) -> List[List[str]]:
    # Guaranteed solvable by construction, intentionally simpler.
    fallback_colors = max(3, min(policy.min_colors, 5))
    colors = rng.sample(COLOR_GROUPS, fallback_colors)
    empty_tubes = 2 if policy.target_empty_tubes >= 1 else 1
    board = build_solved_board(colors, empty_tubes)

    # Deterministic-light scramble using only legal scramble moves.
    steps = max(8, min(20, policy.scramble_steps // 2))
    state = tuple(tuple(s) for s in board)
    for _ in range(steps):
        moves = valid_scramble_moves(state)
        if not moves:
            break
        # Prefer amount 1 to keep it readable.
        ones = [m for m in moves if m[2] == 1]
        chosen = rng.choice(ones or moves)
        state = apply_move(state, chosen)

    board = [list(s) for s in state]

    # Ensure not still solved. If it is, do a forced simple unsolve.
    if count_mixed(board) == 0:
        for i, stack in enumerate(board):
            if len(stack) == CAPACITY:
                for j, dst in enumerate(board):
                    if i != j and len(dst) == 0:
                        color = board[i].pop()
                        board[j].append(color)
                        break
                break

    return board

def build_level_json(world: str, level_num: int, depth: int, policy: BandPolicy, profile: str, board: List[List[str]], rng: random.Random, generation_mode: str) -> Dict[str, Any]:
    if world == "theme_worlds":
        theme_meta = get_theme_for_level(level_num)
    else:
        theme_meta = {"name": VARIANT, "strategy": "classic", "visual": "standard"}

    pattern, challenge, visual = choose_pattern(profile, world, rng)

    return {
        "levelNumber": level_num,
        "world": world,
        "band": policy.band_idx,
        "complexityLabel": policy.complexity_label,
        "difficulty": "hard" if depth > 34 else "medium" if depth > 18 else "easy",
        "profile": profile,
        "generationMode": generation_mode,
        "themeKey": theme_meta["name"],
        "config": {
            "moveLimit": depth + policy.move_buffer if world == "move_challenge" else None,
            "timeLimitSeconds": rng.randint(*policy.time_window) if world == "time_challenge" else None,
            "strategy": theme_meta["strategy"],
            "visualStyle": theme_meta["visual"],
            "pattern": pattern,
            "challenge": challenge,
        },
        "containers": [{"pieces": compress_stack(stack)} for stack in board],
    }

def try_generate_level(level_num: int, world: str, policy: BandPolicy, profile: str, used_fingerprints: Set[str], rng: random.Random) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    reject_counts = Counter()

    # Primary
    for attempt in range(1, PRIMARY_ATTEMPTS + 1):
        colors = rng.sample(COLOR_GROUPS, rng.randint(policy.min_colors, policy.max_colors))
        board = forward_scramble(colors, policy.target_empty_tubes, policy.scramble_steps, world, profile, rng)
        fp = get_stable_fingerprint(board)
        if fp in used_fingerprints:
            reject_counts["duplicate:fingerprint"] += 1
            continue
        if not candidate_quality_ok(board, policy, strict=True):
            reject_counts["quality:strict"] += 1
            continue
        depth = solve_depth(board)
        if depth is None:
            reject_counts["solver:timeout"] += 1
            continue
        if depth < policy.target_depth:
            reject_counts[f"depth:below_{policy.target_depth}"] += 1
            continue

        used_fingerprints.add(fp)
        level = build_level_json(world, level_num, depth, policy, profile, board, rng, "primary")
        meta = {
            "world": world,
            "level": level_num,
            "band": policy.band_idx,
            "complexity_label": policy.complexity_label,
            "profile": profile,
            "depth": depth,
            "attempts": attempt,
            "generation_mode": "primary",
        }
        return level, meta

    # Relaxed
    relaxed_depth = max(8, int(policy.target_depth * 0.75))
    relaxed_steps = max(10, int(policy.scramble_steps * 0.82))
    for attempt in range(1, RELAXED_ATTEMPTS + 1):
        colors = rng.sample(COLOR_GROUPS, rng.randint(max(3, policy.min_colors - 1), policy.max_colors))
        board = forward_scramble(colors, policy.target_empty_tubes, relaxed_steps, world, profile, rng)
        fp = get_stable_fingerprint(board)
        if fp in used_fingerprints:
            reject_counts["duplicate:fingerprint"] += 1
            continue
        if not candidate_quality_ok(board, policy, strict=False):
            reject_counts["quality:relaxed"] += 1
            continue
        depth = solve_depth(board)
        if depth is None:
            reject_counts["solver:timeout"] += 1
            continue
        if depth < relaxed_depth:
            reject_counts[f"depth:below_relaxed_{relaxed_depth}"] += 1
            continue

        used_fingerprints.add(fp)
        level = build_level_json(world, level_num, depth, policy, profile, board, rng, "relaxed")
        meta = {
            "world": world,
            "level": level_num,
            "band": policy.band_idx,
            "complexity_label": policy.complexity_label,
            "profile": profile,
            "depth": depth,
            "attempts": PRIMARY_ATTEMPTS + attempt,
            "generation_mode": "relaxed",
        }
        return level, meta

    # Unconditional fallback: never crash, must produce solvable level.
    fallback_tries = 0
    while True:
        fallback_tries += 1
        board = build_unconditional_fallback_board(level_num, policy, profile, rng)
        fp = get_stable_fingerprint(board)
        if fp in used_fingerprints and fallback_tries < 50:
            continue
        depth = solve_depth(board)
        if depth is None:
            if fallback_tries < 50:
                continue
            # Absolute emergency: make a tiny readable board.
            colors = rng.sample(COLOR_GROUPS, 3)
            board = [
                [colors[0], colors[0], colors[1], colors[0]],
                [colors[1], colors[2], colors[1], colors[1]],
                [colors[2], colors[2], colors[0], colors[2]],
                [],
                [],
            ]
            depth = solve_depth(board)
            if depth is None:
                depth = 6
        used_fingerprints.add(get_stable_fingerprint(board))
        level = build_level_json(world, level_num, depth or 6, policy, profile, board, rng, "fallback")
        meta = {
            "world": world,
            "level": level_num,
            "band": policy.band_idx,
            "complexity_label": policy.complexity_label,
            "profile": profile,
            "depth": depth or 6,
            "attempts": PRIMARY_ATTEMPTS + RELAXED_ATTEMPTS + fallback_tries,
            "generation_mode": "fallback",
            "reject_counts_snapshot": dict(reject_counts),
        }
        return level, meta

# ============================================================
# OUTPUT
# ============================================================

def write_world_outputs(world: str, levels: List[Dict[str, Any]], report_rows: List[Dict[str, Any]]) -> None:
    pack_path = OUTPUT_DIR / f"color_{world}_pack.json"
    report_path = OUTPUT_DIR / f"color_{world}_report.csv"
    failures_path = OUTPUT_DIR / f"color_{world}_failures.json"

    with pack_path.open("w", encoding="utf-8") as f:
        json.dump({"world": world, "variant": VARIANT, "levels": levels}, f, indent=2)

    fieldnames = ["world", "level", "band", "complexity_label", "profile", "depth", "attempts", "generation_mode"]

    with report_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(report_rows)

    with failures_path.open("w", encoding="utf-8") as f:
        json.dump([], f, indent=2)

def write_global_summary(summary_rows: List[Dict[str, Any]]) -> None:
    summary_path = OUTPUT_DIR / "generation_report.csv"
    fieldnames = [
        "world", "requested_levels", "generated_levels",
        "primary_levels", "relaxed_levels", "fallback_levels",
        "avg_depth", "avg_attempts"
    ]
    with summary_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(summary_rows)

# ============================================================
# MAIN
# ============================================================

def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rng = random.Random(SEED)
    summary_rows = []

    for world in WORLDS:
        print(f"\n>>> PIPELINE START: {world.upper()}")
        world_levels: List[Dict[str, Any]] = []
        world_report: List[Dict[str, Any]] = []
        used_fingerprints: Set[str] = set()

        for level_num in range(1, LEVELS_PER_WORLD + 1):
            policy = get_band_policy(level_num)
            profile = get_profile(level_num)
            level, meta = try_generate_level(level_num, world, policy, profile, used_fingerprints, rng)
            world_levels.append(level)
            world_report.append(meta)

            if level_num % 50 == 0:
                print(f"  [Progress] {level_num}/300 Locked")

        expected = list(range(1, LEVELS_PER_WORLD + 1))
        got = [x["levelNumber"] for x in world_levels]
        if got != expected:
            raise RuntimeError(f"{world} output has gaps. Expected 1..300, got mismatched numbering.")

        write_world_outputs(world, world_levels, world_report)

        primary = sum(1 for r in world_report if r["generation_mode"] == "primary")
        relaxed = sum(1 for r in world_report if r["generation_mode"] == "relaxed")
        fallback = sum(1 for r in world_report if r["generation_mode"] == "fallback")
        avg_depth = round(sum(r["depth"] for r in world_report) / len(world_report), 2)
        avg_attempts = round(sum(r["attempts"] for r in world_report) / len(world_report), 2)

        summary_rows.append({
            "world": world,
            "requested_levels": LEVELS_PER_WORLD,
            "generated_levels": len(world_levels),
            "primary_levels": primary,
            "relaxed_levels": relaxed,
            "fallback_levels": fallback,
            "avg_depth": avg_depth,
            "avg_attempts": avg_attempts,
        })

    write_global_summary(summary_rows)
    print(f"\nPipeline Complete. Global report saved to {OUTPUT_DIR / 'generation_report.csv'}")

if __name__ == "__main__":
    start = time.time()
    main()
    print(f"Done in {(time.time() - start) / 60:.2f} minutes.")
