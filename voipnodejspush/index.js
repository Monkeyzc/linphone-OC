
var express = require('express')
var app = express()
var apn = require('apn')

var options = {
  cert: './VOIP.pem',
  key: './VOIP.pem',
  passphrase: '1234',
  production: true,
  voip: true,
  address: 'api.sandbox.push.apple.com'
}

var apnProvider = new apn.Provider(options)

let note = new apn.Notification({
  alert: 'Breaking News: I just sent my first Push Notification'
})

note.topic = 'com.unicare.linphoneOC.voip'

// 发送 voip 通知
app.post('/sendVoipNotification', function (req, res) {
  apnProvider.send(note, 'bd669088a418e1234f0f250025300d43ed81321f42f3960273507a6ebe82a9cf').then(result => {
    console.log('sent:', result.sent.length)
    console.log('failed:', result.failed.length)
    console.log(result.failed)
    console.log(result)

    if (result.failed.length === 0) {
      res.send({
        status: 'success',
        message: 'sendVoipNotification success'
      })
    } else {
      res.send({
        status: 'failed',
        message: 'sendVoipNotification failed'
      })
    }
  })
})

apnProvider.send(note, 'bd669088a418e1234f0f250025300d43ed81321f42f3960273507a6ebe82a9cf').then(result => {
    console.log('sent:', result.sent.length)
    console.log('failed:', result.failed.length)
    console.log(result.failed)
    console.log(result)
  })


app.listen('3000', function (req, res) {
  console.log('server is listening on 3000 port')
})
