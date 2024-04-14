#include<Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>


BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
int transmitTimeThreshold = 10;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"


class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};



 
int motorPin = 33; 
const int MPU_addr=0x68;
int16_t AcX,AcY,AcZ,Tmp,GyX,GyY,GyZ;
 
int minVal=265;
int maxVal=402;
 
double x;
double y;
double z;

int counterLeft=0;
int counterRight=0;
int counterFront=0;
int counterBack=0;
int counterGoodPosture=0;
int generalCounter=0;


void setup()
{
  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);
  pinMode(motorPin, OUTPUT);
  Serial.begin(115200);
  BLEDevice::init("SmartFit");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  
  pCharacteristic->addDescriptor(new BLE2902());
  
  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}

void resetCounters()
{
  counterFront=0;
  counterLeft=0;
  counterRight=0;
  counterBack=0;
  generalCounter=0;
  counterGoodPosture=0;
}



void loop()
{
    

    if (deviceConnected) {
    Wire.beginTransmission(MPU_addr);
    Wire.write(0x3B);
    Wire.endTransmission(false);
    Wire.requestFrom(MPU_addr,14,true);
    AcX=Wire.read()<<8|Wire.read();
    AcY=Wire.read()<<8|Wire.read();
    AcZ=Wire.read()<<8|Wire.read();
    int xAng = map(AcX,minVal,maxVal,-90,90);
    int yAng = map(AcY,minVal,maxVal,-90,90);
    int zAng = map(AcZ,minVal,maxVal,-90,90);

    x= RAD_TO_DEG * (atan2(-yAng, -zAng)+PI);
    y= RAD_TO_DEG * (atan2(-xAng, -zAng)+PI);
    z= RAD_TO_DEG * (atan2(-yAng, -xAng)+PI);

    if(y<100)                                                        
    {
      z = map(z,90,1600,-90,0);
      z*=0.5;
    }
    else                                                             
    {
      z = map(z,90,170,0,90);
    }

    if(y>140) 
    {                                                      
      x = map(x,93,170,0,90);
    }

    else                                                           
    {
      x = map(x,40,222,-90,0);
    }


    if(x>-15 && x<15 && z>-15 && z<15)
    {
      Serial.println("Good Posture :)");
      counterGoodPosture+=1;
      counterFront=0;
      counterLeft=0;
      counterRight=0;
      counterBack=0;
    }

    else if(x>=0 && z<=0)
    {
      Serial.println("leaned forward by "+String(x)+"°");
      counterFront+=1;
      counterLeft=0;
      counterRight=0;
      counterGoodPosture=0;
      counterBack=0;
    }
    else if(x>0 && z>0 && z>x)
    {
      Serial.println("leaned left by "+String(z)+"°");
      counterFront=0;
      counterLeft+=1;
      counterRight=0;
      counterGoodPosture=0;
      counterBack=0;
    }

    else if(x<0 && z<0 && x>-70.00)
    {
      Serial.println("leaned right by "+String(-1*z)+"°");
      counterFront=0;
      counterLeft=0;
      counterRight+=1;
      counterGoodPosture=0;
      counterBack=0;
      //Serial.println(String(x)+"   "+String(z));
    }

    else if(x<z)
    {
      if(x<-70.00 && z<0.00 && z<-45.00)
      {
        Serial.println("leaned right by "+String(-1*z)+"°");
        counterFront=0;
        counterLeft=0;
        counterRight+=1;
        counterGoodPosture=0;
        counterBack=0;
        //Serial.println(String(x)+"   "+String(z));
      }
      else
      {
        Serial.println("leaned backward by "+String(-1*x)+"°");
        counterFront=0;
        counterLeft=0;
        counterRight=0;
        counterGoodPosture=0;
        counterBack+=1;
        //Serial.println(String(x)+"   "+String(z));
      }
    }

    if(counterGoodPosture==transmitTimeThreshold)
    {
      resetCounters();
      String str = "gA"+String(x)+"B"+String(z)+"C";      
      pCharacteristic->setValue((char*)str.c_str());
      pCharacteristic->notify();
    }

    else if(counterFront==transmitTimeThreshold || counterBack==transmitTimeThreshold || counterLeft==transmitTimeThreshold || counterRight==transmitTimeThreshold)
    {
      digitalWrite(motorPin, HIGH);
      delay(3000);
      digitalWrite(motorPin, LOW);


      if(counterFront==transmitTimeThreshold)
      {
        // bad front posture
        String str = "bfA"+String(x)+"B"+String(z)+"C";      
        pCharacteristic->setValue((char*)str.c_str());
        pCharacteristic->notify();

      }
      else if(counterBack==transmitTimeThreshold)
      {
        // bad back posture
        String str = "bbA"+String(-1*x)+"B"+String(z)+"C";      
        pCharacteristic->setValue((char*)str.c_str());
        pCharacteristic->notify();
        
      }
      else if(counterLeft==transmitTimeThreshold)
      {
        // bad left posture
        String str = "blA"+String(x)+"B"+String(z)+"C";      
        pCharacteristic->setValue((char*)str.c_str());
        pCharacteristic->notify();

      }
      else if(counterRight==transmitTimeThreshold)
      {
        // bad right posture
        String str = "brA"+String(x)+"B"+String(-1*z)+"C";      
        pCharacteristic->setValue((char*)str.c_str());
        pCharacteristic->notify();
      }
      resetCounters();
    }

    else if(generalCounter==transmitTimeThreshold)
    {
      resetCounters();
      String str = "aA"+String(x)+"B"+String(z)+"C";      
      pCharacteristic->setValue((char*)str.c_str());
      pCharacteristic->notify();
    }
    generalCounter++; 
    delay(1000);
    }
    
    oldDeviceConnected = deviceConnected;
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); 
        pServer->startAdvertising(); 
    }
    
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
}