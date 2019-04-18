
# react-native-stomp-websocket

## Getting started

`$ npm install react-native-stomp-websocket --save`

`$ react-native link react-native-stomp-websocket`




#### 만든이유
RN 0.57이상부터 널캐릭터에 대한 버그가 있습니다.

문제는 스톰프EOL이 널캐릭터 여서 작동을 안한다는거....

스톰프 쓸라면 써야 하니 직접 뽑아서 ^@로 종료하게 하고

해당 문자열을 replace시켜서 종료시킵니다.

내용에 최대한 ^@가 없이 작동하시면 이상없을듯합니다.


React Native JSC has a 'NULL Character' Bug

참고 URL.. 
https://stackoverflow.com/questions/47598305/react-native-stomp-websocket-not-working-in-android



## Usage
```javascript

import StompWS from 'react-native-stomp-websocket';

const client = StompWS.client('[STOMP URL]');
client.debug = (text) => console.log(text);
client.connect("[login]", "[passcode]", () => {
  alert('success');
}, function (e) {
  alert('errr');
  console.log(e);
});

```
