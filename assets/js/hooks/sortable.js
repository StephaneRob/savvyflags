import { Sortable } from 'sortablejs'

export default {
  mounted() {
    new Sortable(this.el, {
      animation: 150,
      delay: 100,
      dragClass: 'drag-item',
      ghostClass: 'drag-ghost',
      handle: '.handler',
      forceFallback: true,
      onEnd: e => {
        let params = { old: e.oldIndex, new: e.newIndex, ...e.item.dataset }
        this.pushEventTo(this.el, 'reposition', params)
      },
    })
  },
}
