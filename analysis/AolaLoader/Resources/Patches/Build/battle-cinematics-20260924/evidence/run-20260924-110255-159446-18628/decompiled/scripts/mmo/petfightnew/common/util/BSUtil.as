package mmo.petfightnew.common.util
{
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightData;
   import mmo.play.petfight.common.config.FightBSConfig;
   
   public class BSUtil
   {
      
      public function BSUtil()
      {
         super();
      }
      
      public static function parseBS(param1:String) : String
      {
         var _loc7_:String = null;
         var _loc8_:Array = null;
         if(param1 == null || param1 == "")
         {
            return "";
         }
         var _loc2_:Array = param1.split(",");
         var _loc3_:String = "";
         var _loc4_:Object = {};
         var _loc5_:Boolean = false;
         var _loc6_:int = int(_loc2_.length - 1);
         while(_loc6_ >= 0)
         {
            if(FightBSConfig.isUsefulBS(_loc2_[_loc6_]))
            {
               _loc3_ = _loc2_[_loc6_];
            }
            else if(FightBSConfig.isExtNotify(_loc2_[_loc6_]))
            {
               _loc7_ = FightBSConfig.getExtNotify(_loc2_[_loc6_]);
               _loc8_ = _loc7_.split("=");
               _loc4_[_loc8_[0]] = _loc8_[1];
               _loc5_ = true;
            }
            _loc6_--;
         }
         if(_loc5_)
         {
            dispatchExtNotify(_loc4_);
         }
         return _loc3_;
      }
      
      public static function parseBackGroundUp(param1:String) : Array
      {
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc2_:int = -1;
         var _loc3_:int = -1;
         if(param1 == null || param1 == "")
         {
            return [_loc2_,_loc3_];
         }
         var _loc4_:Array = param1.split(",");
         var _loc5_:int = int(_loc4_.length - 1);
         while(_loc5_ >= 0)
         {
            if(_loc4_[_loc5_].indexOf("bccd_") != -1)
            {
               _loc6_ = parseInt(_loc4_[_loc5_].split("_")[2]);
               _loc7_ = FightData.instance.myInfo.isLocalIdAndSlotIdSame() ? 1 : 2;
               if(_loc6_ == _loc7_)
               {
                  _loc2_ = parseInt(_loc4_[_loc5_].split("_")[1]);
               }
               else
               {
                  _loc3_ = parseInt(_loc4_[_loc5_].split("_")[1]);
               }
            }
            _loc5_--;
         }
         return [_loc2_,_loc3_];
      }
      
      public static function parseDiJieShiPetUp(param1:String) : int
      {
         var _loc2_:int = -1;
         if(param1 == null || param1 == "")
         {
            return _loc2_;
         }
         var _loc3_:Array = param1.split(",");
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.length)
         {
            if(_loc3_[_loc4_].indexOf("dijieshird_") != -1)
            {
               _loc2_ = parseInt(_loc3_[_loc4_].split("_")[1]);
               break;
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function parseXingHuanShiPetDown(param1:String) : Array
      {
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc2_:int = -1;
         var _loc3_:int = -1;
         if(param1 == null || param1 == "")
         {
            return [_loc2_,_loc3_];
         }
         var _loc4_:Array = param1.split(",");
         var _loc5_:int = int(_loc4_.length - 1);
         while(_loc5_ >= 0)
         {
            if(_loc4_[_loc5_].indexOf("xhs_") != -1)
            {
               _loc6_ = parseInt(_loc4_[_loc5_].split("_")[1]);
               _loc7_ = FightData.instance.myInfo.isLocalIdAndSlotIdSame() ? 1 : 2;
               if(_loc6_ == _loc7_)
               {
                  _loc2_ = parseInt(_loc4_[_loc5_].split("_")[2]);
               }
               else
               {
                  _loc3_ = parseInt(_loc4_[_loc5_].split("_")[2]);
               }
            }
            _loc5_--;
         }
         return [_loc2_,_loc3_];
      }
      
      public static function parseXingHuanShiTurnCount(param1:String) : int
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:Array = param1.split(",");
         var _loc4_:int = int(_loc3_.length - 1);
         while(_loc4_ >= 0)
         {
            if(_loc3_[_loc4_].indexOf("xhs_") != -1)
            {
               _loc5_ = parseInt(_loc3_[_loc4_].split("_")[1]);
               _loc6_ = FightData.instance.myInfo.isLocalIdAndSlotIdSame() ? 1 : 2;
               if(_loc5_ == _loc6_)
               {
                  _loc2_ = parseInt(_loc3_[_loc4_].split("_")[3]);
               }
            }
            _loc4_--;
         }
         return _loc2_;
      }
      
      public static function parseXianJingJi(param1:String) : Object
      {
         var _loc7_:String = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc2_:int = -1;
         var _loc3_:int = -1;
         var _loc4_:int = -1;
         var _loc5_:Array = param1.split(",");
         var _loc6_:int = int(_loc5_.length - 1);
         while(_loc6_ >= 0)
         {
            if(_loc5_[_loc6_].indexOf("celing=") != -1)
            {
               _loc7_ = _loc5_[_loc6_].split("=")[1];
               _loc8_ = parseInt(_loc7_.split("_")[0]);
               _loc9_ = FightData.instance.myInfo.isLocalIdAndSlotIdSame() ? 1 : 2;
               if(_loc8_ == _loc9_)
               {
                  _loc2_ = parseInt(_loc7_.split("_")[1]);
                  _loc3_ = parseInt(_loc7_.split("_")[2]);
                  _loc4_ = parseInt(_loc7_.split("_")[3]);
               }
            }
            _loc6_--;
         }
         return {
            "skillId":_loc2_,
            "curCD":_loc3_,
            "raceId":_loc4_
         };
      }
      
      public static function getIsInHunDunJueDouState() : Boolean
      {
         var _loc1_:Array = FightData.instance.curBs.split(",");
         var _loc2_:int = int(_loc1_.length - 1);
         while(_loc2_ >= 0)
         {
            if(_loc1_[_loc2_].indexOf("hdjdzc") != -1)
            {
               return true;
            }
            _loc2_--;
         }
         return false;
      }
      
      private static function dispatchExtNotify(param1:Object) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.EXT_NOTIFY,{"ext":param1}));
      }
   }
}

