export default {
  mounted() {
    const input = this.el.getElementsByTagName('input')[0]
    let results

    input.addEventListener('focus', () => {
      results = this.el.getElementsByClassName('search-results')[0]
      results?.classList.remove('hidden')
    })

    input.addEventListener('blur', () => {
      results?.classList.add('hidden')
    })

    input.addEventListener('keyup', e => {
      e.preventDefault()
      e.stopPropagation()
    })
  },
}
