var parseHeartRate = function(data){
  if (data instanceof Uint8Array) {
    var bytes = data;
    //Check for data
    if (bytes.length === 0) {
      console.log('Subscription result had zero length data');
      return;
    }

    //Get the first byte that contains flags
    var flag = bytes[0];

    //Check if u8 or u16 and get heart rate
    var hr;
    if ((flag & 0x01) === 1) {
      var u16bytes = bytes.buffer.slice(1, 3);
      var u16 = new Uint16Array(u16bytes)[0];
      hr = u16;
    } else {
      var u8bytes = bytes.buffer.slice(1, 2);
      var u8 = new Uint8Array(u8bytes)[0];
      hr = u8;
    }
    return hr;
  } else {
    return data.readUInt8(1);
  }
}

module.exports = parseHeartRate;
