/*
Code based on this post:
http://www.hessmer.org/blog/2011/01/30/quadrature-encoder-too-fast-for-arduino-with-solution/

*/
#include <digitalWriteFast.h>  // library for high performance reads and writes by jrraines

#define EncoderPinA 2
#define EncoderPinB 3
#define EncoderIsReversed
volatile bool _EncoderBSet;
volatile long _EncoderTicks = 0;
unsigned long ttime = 0; // time in milliseconds
String str = ""; // incoming message from PTB computer

void setup() {
  Serial.begin(9600); // I haven't had luck with 115200. Might be my USB hub. 9600 works fine.
  
  pinMode(EncoderPinA, INPUT_PULLUP);      // sets pin A as input
  pinMode(EncoderPinB, INPUT_PULLUP);      // sets pin B as input
  attachInterrupt(digitalPinToInterrupt(EncoderPinA), HandleInterruptA, RISING);
    
}

void loop() {
  
  // read from serial buffer, check for reset command
  if (Serial.available() > 0)
  {
    String str = Serial.readString();
      
     if (str.equals("reset")) {
       _EncoderTicks = 0;
     }
     
     delay(2);  //delay 2 milliseconds 
  }
  //Just print to string on the serial line
  ttime = millis();
  
  Serial.print("time:");
  Serial.print(ttime);
  Serial.print(",count:");
  Serial.print(_EncoderTicks);
  Serial.println(",");
  
  delay(2);  //delay 2 milliseconds   
}

// Interrupt service routines for the quadrature encoder
void HandleInterruptA()
{
  // Test transition; since the interrupt will only fire on 'rising' we don't need to read pin A
  _EncoderBSet = digitalReadFast(EncoderPinB);   // read the input pin
  // and adjust counter + if A leads B
  #ifdef EncoderIsReversed
    _EncoderTicks -= _EncoderBSet ? -1 : +1;
  #else
    _EncoderTicks += _EncoderBSet ? -1 : +1;
  #endif
}

