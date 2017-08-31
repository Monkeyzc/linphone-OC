
var express = require('express')
var bodyParser = require('body-parser')
var app = express()
var apn = require('apn')

app.use(bodyParser.urlencoded({extended: true}))
app.use(bodyParser.json())

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
  var token = req.body.token
  console.log(req.body)
  console.log(`token: ${token}`)
  if (token) {
    apnProvider.send(note, token).then(result => {
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
  } else {
    res.send({
      status: 'failed',
      message: 'Please send token'
    })
  }
})

app.listen('3000', function (req, res) {
  console.log('server is listening on 3000 port')
})
