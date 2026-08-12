import unittest
from pathlib import Path

SKILL = Path(__file__).resolve().parents[1] / "SKILL.md"
PIPELINE = Path(__file__).resolve().parents[1] / "references" / "pipeline.md"


class SingleFinalChromaPassTest(unittest.TestCase):
    def test_cleanup_runs_only_after_v2_assembly(self) -> None:
        skill = SKILL.read_text()
        instructions = PIPELINE.read_text()

        self.assertIn("[execution pipeline](references/pipeline.md)", skill)
        self.assertEqual(instructions.count("scripts/despill_chroma_edges.py"), 1)
        self.assertNotIn("chroma-despill-standard.json", instructions)
        self.assertLess(
            instructions.index("scripts/assemble_extended_atlas.py"),
            instructions.index("scripts/despill_chroma_edges.py"),
        )


if __name__ == "__main__":
    unittest.main()
