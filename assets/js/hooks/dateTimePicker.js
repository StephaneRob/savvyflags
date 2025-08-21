import flatpickr from 'flatpickr'

export default {
  mounted() {
    flatpickr(this.el, {
      enableTime: true,
      altFormat: 'd/m/Y H:i',
      dateFormat: 'Z',
      minuteIncrement: 1,
      time_24hr: true,
      altInput: true,
      static: true,
      wrap: false,
      minDate: 'today',
    })
  },
}
