package mmo.petfightnew.common.startmovie
{
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   
   public class SendLoadingHelper
   {
      
      public static const CMD_FIGHT_LOAD:String = "preFightLoad";
      
      public function SendLoadingHelper()
      {
         super();
      }
      
      public static function sendLoadingInfo(param1:Number) : void
      {
         var _loc6_:PlayerBattleInfo = null;
         var _loc2_:Array = FightData.instance.playerInfo || [];
         var _loc3_:* = "";
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc6_ = _loc2_[_loc4_] as PlayerBattleInfo;
            if(_loc6_ != null)
            {
               _loc3_ += _loc6_.PMMasterId.toString();
               if(_loc4_ != _loc2_.length - 1)
               {
                  _loc3_ += ",";
               }
            }
            _loc4_++;
         }
         var _loc5_:String = UserInfo.userId.toString() + ":" + param1.toString();
         if(_loc3_ != "")
         {
            send(_loc3_,_loc5_);
         }
      }
      
      private static function send(param1:String, param2:String) : void
      {
         var _loc3_:Object = {
            "ul":param1,
            "msg":param2
         };
         SocketClient.instance.sendXtMessage("PetExtension2",CMD_FIGHT_LOAD,_loc3_);
      }
   }
}

