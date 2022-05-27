const env1 = process.env['env1']

function main(args) {
    console.log(env1)
    let name = args.name || 'stranger'
    let greeting = 'Hello ' + name + '!'
    console.log(greeting)
    return {"body": greeting}
  }
  
