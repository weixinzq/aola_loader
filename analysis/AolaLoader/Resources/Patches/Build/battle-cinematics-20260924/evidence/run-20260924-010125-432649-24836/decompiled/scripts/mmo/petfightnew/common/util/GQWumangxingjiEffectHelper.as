package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class GQWumangxingjiEffectHelper
   {
      
      private static const FLA:String = "gqpet/wumangxingji/effect/wumangxingjieffect_";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.wumangxingji.effect.GQWumangxingjiEffectMv_";
      
      public function GQWumangxingjiEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var hasView:Boolean;
         var pmSvr:IPMService;
         var isInWumangxingjiState:Boolean;
         var skillId:int;
         var key:String = null;
         var skillLv:int = 0;
         var mc:MovieClip = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var face:int = getFace(locaId);
         var raceId:int = thePet.raceId % 10000;
         key = KEY_STAND + "_" + locaId + "_" + face + "#" + raceId + "#wumangxingjieffect";
         var i:int = layer.numChildren - 1;
         while(i >= 0)
         {
            mc = layer.getChildAt(i) as MovieClip;
            if(mc)
            {
               if(mc.name.indexOf(KEY_STAND + "_" + locaId + "_" + face) != -1 && parseInt(mc.name.split("#")[1]) != raceId)
               {
                  DisplayUtil.stopAndRemove(mc);
               }
            }
            i--;
         }
         hasView = layer.getChildByName(key) != null;
         pmSvr = ServiceContainer.getService(IPMService);
         isInWumangxingjiState = StatusUtil.getIsInWumangXingjiState(thePet);
         skillId = StatusUtil.getWumangXingjiStateSkillId(thePet);
         skillLv = 0;
         if(skillId > 0)
         {
            skillLv = int(pmSvr.customData.pmSkillMap.getSkill(skillId).getSkillLevel());
         }
         if(hasView)
         {
            if(!isInWumangxingjiState)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            else
            {
               mc = layer.getChildByName(key) as MovieClip;
               mc.gotoAndStop(skillLv);
               mc.visible = true;
            }
         }
         else if(isInWumangxingjiState)
         {
            ResScheduler.getRes(ResParams.createTempByDomain(FLA + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
            {
               var mcFrame:* = undefined;
               var mc:MovieClip = param1;
               var domain:ApplicationDomain = param2;
               mc.x = x;
               mc.y = y - 180;
               mc.name = key;
               layer.addChild(mc);
               mc.gotoAndStop(1);
               mcFrame = mc.getChildByName("mcFrame") as MovieClip;
               mcFrame.addFrameScript(mcFrame.totalFrames - 1,function():void
               {
                  var _loc1_:* = undefined;
                  mcFrame.stop();
                  if(Boolean(mc) && Boolean(mc.parent))
                  {
                     _loc1_ = skillLv + 2 > mc.totalFrames ? mc.totalFrames : skillLv + 2;
                     mc.gotoAndStop(_loc1_);
                  }
               });
               mcFrame.gotoAndPlay(1);
            },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND + raceId.toString(),ResPriority.LOW));
         }
      }
      
      private static function getFace(param1:int) : int
      {
         return FightData.instance.isMySide(param1) ? 2 : 1;
      }
   }
}

