/**
 * Сторож для Pi: те же запреты, что у исполнителя на Claude Code (tools/executor-settings.json).
 * Опасные команды bash и правка проверок/заданий/спецификаций блокируются без вопросов.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const BANNED_BASH = [
	/(^|[;&|`(\s])(rm|mv|xattr|osascript|open|curl|wget|sudo|trash|killall|pkill)\s/i,
	/\bgit\s+(push|reset|clean|checkout\s+--|rebase)\b/i,
	/>\s*(tools|docs\/tasks)\//, /\b(tools|docs\/tasks)\/\S*\s*<</,
	/(^|\s)(\.\.\/){2,}/,            // выход за пределы проекта по относительному пути
];
const PROTECTED = [/(^|\/)tools\//, /(^|\/)docs\/tasks\//, /(^|\/)docs\/UI-SPEC\.md$/, /(^|\/)AGENTS\.md$/];

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		if (event.toolName === "bash") {
			const cmd = String(event.input.command ?? "");
			if (BANNED_BASH.some((r) => r.test(cmd))) {
				return { block: true, reason: "Запрещено правилами проекта (AGENTS.md): удаление, перемещение, xattr, сеть и выход за пределы проекта." };
			}
		}
		if (event.toolName === "edit" || event.toolName === "write") {
			const p = String(event.input.path ?? event.input.file_path ?? "");
			if (PROTECTED.some((r) => r.test(p)) || !p.includes("treesize-mac") && p.startsWith("/")) {
				return { block: true, reason: "Этот файл менять нельзя (AGENTS.md, правило 4) или он вне проекта." };
			}
		}
		return undefined;
	});
}
