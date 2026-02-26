"""Tests for context/a2a-network.md — A2A mesh topology and routing rules."""

import pathlib
import re

import pytest

REPO_ROOT = pathlib.Path(__file__).parent.parent
CONTEXT_DIR = REPO_ROOT / "context"
A2A_NETWORK_FILE = CONTEXT_DIR / "a2a-network.md"


@pytest.fixture
def content():
    """Load the a2a-network.md file content."""
    assert A2A_NETWORK_FILE.exists(), f"{A2A_NETWORK_FILE} does not exist"
    return A2A_NETWORK_FILE.read_text()


@pytest.fixture
def lower_content(content):
    """Lower-cased file content for case-insensitive checks."""
    return content.lower()


class TestDirectoryAndFileExist:
    def test_context_directory_exists(self):
        assert CONTEXT_DIR.is_dir(), "context/ directory must exist"

    def test_a2a_network_file_exists(self):
        assert A2A_NETWORK_FILE.is_file(), "context/a2a-network.md must exist"


class TestSection1AgentNetworkHeader:
    """Section 1: A2A Agent Network header."""

    def test_has_agent_network_header(self, content):
        assert "# A2A Agent Network" in content

    def test_mentions_5_agent_mesh(self, content, lower_content):
        assert "5-agent mesh" in content or "five-agent mesh" in lower_content

    def test_mentions_a2a_protocol(self, content):
        assert "A2A protocol" in content

    def test_mentions_a2a_send_operation(self, content):
        assert 'a2a(operation="send"' in content


class TestSection2AgentsOnTheNetwork:
    """Section 2: Agents on the Network with all 5 agents, URLs, and skills."""

    def test_has_agents_on_network_section(self, content):
        assert "Agents on the Network" in content

    # --- ai-os ---
    def test_ai_os_listed(self, content):
        assert "ai-os" in content

    def test_ai_os_url(self, content):
        assert "http://localhost:8210" in content

    def test_ai_os_skills(self, content):
        for skill in [
            "calendar-query",
            "email-search",
            "task-lookup",
            "file-access",
            "system-status",
        ]:
            assert skill in content, f"ai-os skill '{skill}' missing"

    # --- lifeline ---
    def test_lifeline_listed(self, content):
        assert re.search(r"\blifeline\b", content), "agent 'lifeline' not found"

    def test_lifeline_url(self, content):
        assert "http://localhost:8211" in content

    def test_lifeline_skills(self, content):
        for skill in [
            "people-lookup",
            "relationship-context",
            "meeting-history",
            "contact-search",
        ]:
            assert skill in content, f"lifeline skill '{skill}' missing"

    # --- lifeline-demo ---
    def test_lifeline_demo_listed(self, content):
        assert "lifeline-demo" in content

    def test_lifeline_demo_url(self, content):
        assert "http://localhost:8212" in content

    def test_lifeline_demo_skills(self, content):
        for skill in [
            "calendar-management",
            "email-triage",
            "file-management",
            "task-delegation",
        ]:
            assert skill in content, f"lifeline-demo skill '{skill}' missing"

    # --- hive-slack ---
    def test_hive_slack_listed(self, content):
        assert "hive-slack" in content

    def test_hive_slack_url(self, content):
        assert "http://localhost:8213" in content

    def test_hive_slack_skills(self, content):
        for skill in [
            "code-execution",
            "file-generation",
            "technical-research",
            "code-review",
            "channel-search",
            "team-chatter",
        ]:
            assert skill in content, f"hive-slack skill '{skill}' missing"

    # --- cortex ---
    def test_cortex_listed(self, content):
        assert "cortex" in content

    def test_cortex_url(self, content):
        assert "http://localhost:8214" in content

    def test_cortex_is_you(self, content):
        # The cortex entry should indicate "THIS IS YOU"
        assert "THIS IS YOU" in content

    def test_cortex_skills(self, content):
        for skill in [
            "attention-state",
            "notification-score",
            "focus-mode-status",
            "notification-history",
            "notification-content-search",
        ]:
            assert skill in content, f"cortex skill '{skill}' missing"


class TestSection3YourRoleCortex:
    """Section 3: Your Role: cortex with routing rules."""

    def test_has_your_role_section(self, content):
        assert "Your Role" in content and "cortex" in content

    def test_routing_calendar_to_ai_os(self, content, lower_content):
        # Calendar context → ai-os
        assert "calendar" in lower_content
        assert "ai-os" in content

    def test_routing_sender_relationship_to_lifeline(self, content, lower_content):
        assert "sender" in lower_content or "relationship" in lower_content
        assert "lifeline" in content

    def test_routing_coding_to_hive_slack(self, content, lower_content):
        assert "coding" in lower_content or "technical" in lower_content
        assert "hive-slack" in content

    def test_routing_slack_channel_to_hive_slack(self, lower_content):
        assert "slack channel" in lower_content or "channel context" in lower_content

    def test_routing_email_file_to_ai_os(self, lower_content):
        assert "email" in lower_content or "file" in lower_content

    def test_dont_reach_out_when_local(self, lower_content):
        assert "don't reach out" in lower_content or "answer locally" in lower_content


class TestSection4ProactiveTriggers:
    """Section 4: Proactive Triggers (CUSTOMIZABLE) with 3 default rules."""

    def test_has_proactive_triggers_section(self, content):
        assert "Proactive Triggers" in content

    def test_marked_customizable(self, content):
        assert "CUSTOMIZABLE" in content

    def test_trigger_high_urgency_notification(self, content, lower_content):
        # Notification scored >= 0.9 urgency → notify ai-os
        assert "0.9" in content
        assert "urgency" in lower_content

    def test_trigger_focus_mode_change(self, lower_content):
        assert "focus mode" in lower_content
        # Should mention enter and exit
        assert "enter" in lower_content or "exit" in lower_content

    def test_trigger_notification_burst(self, lower_content):
        assert "burst" in lower_content
        assert "single source" in lower_content or "single-source" in lower_content

    def test_all_triggers_default_to_ai_os(self, content):
        # All 3 proactive triggers should target ai-os only
        # Find the proactive triggers section and verify ai-os is the target
        triggers_section = (
            content.split("Proactive Triggers")[1]
            if "Proactive Triggers" in content
            else ""
        )
        assert "ai-os" in triggers_section, "Proactive triggers must target ai-os"

    def test_other_agents_can_ask_cortex(self, lower_content):
        # Other agents can ask Cortex directly
        assert (
            "agents can ask cortex" in lower_content
            or "ask cortex directly" in lower_content
        )

    def test_cortex_does_not_proactively_push_to_others(self, lower_content):
        assert (
            "does not proactively push" in lower_content
            or "not proactively push" in lower_content
        )
