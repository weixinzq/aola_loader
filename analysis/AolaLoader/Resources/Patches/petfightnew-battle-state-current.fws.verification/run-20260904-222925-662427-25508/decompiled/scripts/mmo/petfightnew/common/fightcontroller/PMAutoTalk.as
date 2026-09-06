package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.config.PMTalkConfig;
   import mmo.petfightnew.common.manager.FightMovieManager;
   
   public class PMAutoTalk
   {
      
      public function PMAutoTalk()
      {
         super();
      }
      
      public static function checkTalk(param1:FightPanel, param2:Function) : void
      {
         var _loc5_:PlayerBattleInfo = null;
         var _loc6_:Object = null;
         var _loc7_:String = null;
         var _loc8_:Array = null;
         var _loc9_:* = false;
         var _loc10_:int = 0;
         if(FightData.instance.playerInfo == null)
         {
            return;
         }
         if(FightController.instance.isReplay)
         {
            param2.apply();
            return;
         }
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         while(_loc4_ < FightData.instance.playerInfo.length)
         {
            _loc5_ = FightData.instance.playerInfo[_loc4_] as PlayerBattleInfo;
            if(_loc5_ != null)
            {
               _loc6_ = PMTalkConfig.talkMap[PetBriefInfo(_loc5_.myPets[0]).raceId] as Object;
               if(_loc6_ != null)
               {
                  for(_loc7_ in _loc6_)
                  {
                     _loc8_ = _loc7_.split("-");
                     _loc9_ = false;
                     _loc10_ = FightController.instance.turnCount + 1;
                     if(_loc8_.length == 1)
                     {
                        _loc9_ = _loc10_ == parseInt(_loc8_[0]);
                     }
                     else if(_loc8_.length == 2)
                     {
                        _loc9_ = _loc10_ >= parseInt(_loc8_[0]) && _loc10_ <= parseInt(_loc8_[1]);
                     }
                     else if(_loc8_.length == 3)
                     {
                        if(_loc10_ >= _loc8_[1])
                        {
                           _loc9_ = _loc10_ % _loc8_[1] == _loc8_[2];
                        }
                     }
                     if(_loc9_)
                     {
                        _loc3_ = _loc6_[_loc7_];
                        break;
                     }
                  }
                  if(_loc3_ != null)
                  {
                     break;
                  }
               }
            }
            _loc4_++;
         }
         if(_loc3_ != null)
         {
            play(_loc3_.pathName,_loc3_.className,param1,param2);
         }
         else
         {
            param2.apply();
         }
      }
      
      private static function play(param1:String, param2:String, param3:FightPanel, param4:Function) : void
      {
         var pathName:String = param1;
         var className:String = param2;
         var fightPanel:FightPanel = param3;
         var callBack:Function = param4;
         ResScheduler.getResource(pathName,function(param1:MovieClip):void
         {
            var mc:MovieClip = param1;
            FightMovieManager.instance.addMovie(mc);
            mc.addFrameScript(mc.totalFrames - 1,function():void
            {
               FightMovieManager.instance.removeMovie(mc);
               mc.stop();
               DisplayUtil.stopAndRemove(mc);
               callBack.apply();
            });
            fightPanel.addChild(mc);
            mc.gotoAndPlay(1);
         },className,null,null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
      }
   }
}

