import { basicSetup } from 'codemirror'
import { EditorState } from '@codemirror/state'
import { EditorView } from '@codemirror/view'
import { json } from '@codemirror/lang-json'

export default {
  mounted() {
    const initialValue = this.el.dataset.initialValue

    const listeners = EditorView.updateListener.of(v => {
      if (v.docChanged) {
        clearTimeout(this.debounceTimeout)
        this.debounceTimeout = setTimeout(() => {
          this.pushEvent('evaluate', { attributes: v.state.doc.toString() })
        }, 300)
      }
    })

    let startState = EditorState.create({
      doc: initialValue,
      extensions: [basicSetup, listeners, json()],
    })

    this.view = new EditorView({
      state: startState,
      parent: this.el,
    })
  },

  destroyed() {
    if (this.view) this.view.destroy()
  },
}
