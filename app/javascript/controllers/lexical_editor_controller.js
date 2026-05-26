import { Controller } from "@hotwired/stimulus"
import {
  createEditor,
  $getRoot,
  $createParagraphNode,
  $getSelection,
  $isRangeSelection,
  FORMAT_TEXT_COMMAND,
  UNDO_COMMAND,
  REDO_COMMAND
} from "lexical"
import {
  HeadingNode,
  QuoteNode,
  registerRichText,
  $createHeadingNode,
  $createQuoteNode,
  $isHeadingNode
} from "@lexical/rich-text"
import {
  ListNode,
  ListItemNode,
  registerList,
  INSERT_ORDERED_LIST_COMMAND,
  INSERT_UNORDERED_LIST_COMMAND,
  $isListNode
} from "@lexical/list"
import { registerHistory, createEmptyHistoryState } from "@lexical/history"
import { $generateHtmlFromNodes, $generateNodesFromDOM } from "@lexical/html"
import { CodeNode, CodeHighlightNode, registerCodeHighlighting, $createCodeNode, $isCodeNode } from "@lexical/code"
import Prism from "prismjs"
import Tribute from "tributejs"

export default class extends Controller {
  static targets = ["editor", "input"]
  static values = {
    placeholder: { type: String, default: "Escribe aquí..." },
    mentions: { type: Boolean, default: false },
    projectId: { type: Number, default: 0 },
    todoId: { type: Number, default: 0 },
    taskId: { type: Number, default: 0 }
  }

  connect() {
    this.editor = createEditor({
      namespace: "TivoEditor",
      nodes: [HeadingNode, QuoteNode, ListNode, ListItemNode, CodeNode, CodeHighlightNode],
      onError: (error) => console.error("[Lexical]", error)
    })

    this.editor.setRootElement(this.editorTarget)

    window.Prism = Prism
    registerRichText(this.editor)
    registerList(this.editor)
    registerCodeHighlighting(this.editor)
    registerHistory(this.editor, createEmptyHistoryState(), 300)

    // Load existing HTML content into the editor
    const existingHtml = this.hasInputTarget ? this.inputTarget.value : ""
    if (existingHtml && existingHtml.trim()) {
      this.editor.update(() => {
        const parser = new DOMParser()
        const dom = parser.parseFromString(existingHtml, "text/html")
        const nodes = $generateNodesFromDOM(this.editor, dom)
        const root = $getRoot()
        root.clear()
        nodes.forEach(node => root.append(node))
      }, { discrete: true })
    }

    // Sync editor state to hidden input on every update
    this.editor.registerUpdateListener(({ editorState }) => {
      editorState.read(() => {
        const html = $generateHtmlFromNodes(this.editor, null)
        if (this.hasInputTarget) {
          this.inputTarget.value = html
        }
      })
      this.updateToolbarState()
    })

    if (this.mentionsValue) {
      this.setupMentions()
    }
  }

  disconnect() {
    if (this.tribute) {
      this.tribute.detach(this.editorTarget)
    }
    if (this.editor) {
      this.editor.setRootElement(null)
    }
  }

  // ─── Toolbar commands ────────────────────────────────────────────────────

  formatBold(e) {
    e.preventDefault()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, "bold")
    this.editorTarget.focus()
  }

  formatItalic(e) {
    e.preventDefault()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, "italic")
    this.editorTarget.focus()
  }

  formatUnderline(e) {
    e.preventDefault()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, "underline")
    this.editorTarget.focus()
  }

  formatStrikethrough(e) {
    e.preventDefault()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, "strikethrough")
    this.editorTarget.focus()
  }

  formatH1(e) {
    e.preventDefault()
    this.toggleHeading("h1")
  }

  formatH2(e) {
    e.preventDefault()
    this.toggleHeading("h2")
  }

  formatH3(e) {
    e.preventDefault()
    this.toggleHeading("h3")
  }

  formatBulletList(e) {
    e.preventDefault()
    this.editor.dispatchCommand(INSERT_UNORDERED_LIST_COMMAND, undefined)
    this.editorTarget.focus()
  }

  formatOrderedList(e) {
    e.preventDefault()
    this.editor.dispatchCommand(INSERT_ORDERED_LIST_COMMAND, undefined)
    this.editorTarget.focus()
  }

  formatQuote(e) {
    e.preventDefault()
    this.toggleQuote()
  }

  formatInlineCode(e) {
    e.preventDefault()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, "code")
    this.editorTarget.focus()
  }

  formatCodeBlock(e) {
    e.preventDefault()
    this.toggleCodeBlock()
  }

  undo(e) {
    e.preventDefault()
    this.editor.dispatchCommand(UNDO_COMMAND, undefined)
    this.editorTarget.focus()
  }

  redo(e) {
    e.preventDefault()
    this.editor.dispatchCommand(REDO_COMMAND, undefined)
    this.editorTarget.focus()
  }

  // ─── Block type helpers ───────────────────────────────────────────────────

  toggleHeading(tag) {
    this.editor.update(() => {
      const selection = $getSelection()
      if (!$isRangeSelection(selection)) return

      const anchorNode = selection.anchor.getNode()
      const element = anchorNode.getKey() === "root"
        ? anchorNode
        : anchorNode.getTopLevelElementOrThrow()

      if ($isHeadingNode(element) && element.getTag() === tag) {
        const paragraph = $createParagraphNode()
        element.replace(paragraph)
      } else {
        const heading = $createHeadingNode(tag)
        element.replace(heading)
      }
    })
    this.editorTarget.focus()
  }

  toggleQuote() {
    this.editor.update(() => {
      const selection = $getSelection()
      if (!$isRangeSelection(selection)) return

      const anchorNode = selection.anchor.getNode()
      const element = anchorNode.getTopLevelElementOrThrow()

      if (element.getType() === "quote") {
        const paragraph = $createParagraphNode()
        element.replace(paragraph)
      } else {
        const quote = $createQuoteNode()
        element.replace(quote)
      }
    })
    this.editorTarget.focus()
  }

  toggleCodeBlock() {
    this.editor.update(() => {
      const selection = $getSelection()
      if (!$isRangeSelection(selection)) return

      const anchorNode = selection.anchor.getNode()
      const element = anchorNode.getTopLevelElementOrThrow()

      if ($isCodeNode(element)) {
        const paragraph = $createParagraphNode()
        element.replace(paragraph)
      } else {
        const code = $createCodeNode()
        element.replace(code)
      }
    })
    this.editorTarget.focus()
  }

  // ─── Toolbar state sync ───────────────────────────────────────────────────

  updateToolbarState() {
    this.editor.getEditorState().read(() => {
      const selection = $getSelection()
      if (!$isRangeSelection(selection)) return

      this.setButtonActive("bold", selection.hasFormat("bold"))
      this.setButtonActive("italic", selection.hasFormat("italic"))
      this.setButtonActive("underline", selection.hasFormat("underline"))
      this.setButtonActive("strikethrough", selection.hasFormat("strikethrough"))

      const anchorNode = selection.anchor.getNode()
      const element = anchorNode.getKey() === "root"
        ? anchorNode
        : anchorNode.getTopLevelElementOrThrow()

      this.setButtonActive("h1", $isHeadingNode(element) && element.getTag() === "h1")
      this.setButtonActive("h2", $isHeadingNode(element) && element.getTag() === "h2")
      this.setButtonActive("h3", $isHeadingNode(element) && element.getTag() === "h3")
      this.setButtonActive("quote", element.getType() === "quote")
      this.setButtonActive("code-block", $isCodeNode(element))
      this.setButtonActive("inline-code", selection.hasFormat("code"))
      this.setButtonActive("bullet-list", $isListNode(element) && element.getListType() === "bullet")
      this.setButtonActive("ordered-list", $isListNode(element) && element.getListType() === "number")
    })
  }

  setButtonActive(format, isActive) {
    const btn = this.element.querySelector(`[data-format="${format}"]`)
    if (btn) btn.classList.toggle("lexical-toolbar-btn--active", isActive)
  }

  // ─── Mentions ─────────────────────────────────────────────────────────────

  setupMentions() {
    this.tribute = new Tribute({
      trigger: "@",
      values: async (text, callback) => {
        await this.searchUsers(text, callback)
      },
      selectTemplate: (item) => `@${item.original.name}`,
      menuItemTemplate: (item) => `
        <div class="flex items-center gap-2 p-2">
          <div class="w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-white text-sm font-semibold">
            ${item.original.initials}
          </div>
          <div>
            <div class="font-medium text-sm text-gray-900">${item.original.name}</div>
            <div class="text-xs text-gray-500">${item.original.email}</div>
          </div>
        </div>`,
      noMatchTemplate: () => '<span class="text-gray-500 text-sm p-2">No se encontraron usuarios</span>',
      lookup: "name",
      fillAttr: "name",
      allowSpaces: true,
      menuShowMinLength: 1
    })

    this.tribute.attach(this.editorTarget)
  }

  async searchUsers(query, callback) {
    if (!query || query.length < 1) {
      callback([])
      return
    }

    const url = `/projects/${this.projectIdValue}/todos/${this.todoIdValue}/tasks/${this.taskIdValue}/search_members?q=${encodeURIComponent(query)}`
    try {
      const response = await fetch(url)
      if (response.ok) {
        const data = await response.json()
        callback(data.users)
      } else {
        callback([])
      }
    } catch (error) {
      console.error("[Lexical mentions] Error searching users:", error)
      callback([])
    }
  }
}
