import '../css/app.css'

async function addOrder() {
    const response = await fetch('/order', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    })
}
window.addOrder = addOrder