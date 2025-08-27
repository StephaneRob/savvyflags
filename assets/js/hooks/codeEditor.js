import { basicSetup } from 'codemirror'
import { EditorState } from '@codemirror/state'
import { EditorView } from '@codemirror/view'
import { autocompletion } from '@codemirror/autocomplete'
import { json, jsonLanguage } from '@codemirror/lang-json'

export default {
  mounted() {
    const initialValue = this.el.dataset.initialValue
    const attributes = this.el.dataset.attributes

    const listeners = EditorView.updateListener.of(v => {
      if (v.docChanged) {
        clearTimeout(this.debounceTimeout)
        this.debounceTimeout = setTimeout(() => {
          this.pushEvent('evaluate', { payload: v.state.doc.toString() })
        }, 300)
      }
    })

    let startState = EditorState.create({
      doc: initialValue,
      extensions: [
        json(),
        autocompletion(),
        jsonLanguage.data.of({
          autocomplete: attributes ? JSON.parse(attributes) : [],
        }),
        basicSetup,
        listeners,
      ],
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
