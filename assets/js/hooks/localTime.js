export default {
  mounted() {
    const utcDatetime = this.el.innerText.trim()
    const date = new Date(utcDatetime)
    this.el.innerText = date.toLocaleString()
  },
}
