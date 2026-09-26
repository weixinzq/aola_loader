package mmo.petfightnew.common.skilleffect
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQXingZhiYuSkillParse;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   
   public class GQXingZhiYuEffectHelper
   {
      
      private static const FLA:String = "gqpet/xingzhiyu/effect/xingzhiyueffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.xingzhiyu.effect.GQXingZhiYuEffectMv_";
      
      private static var _lastYuYanResult:int = -1;
      
      private static var _turn:int = -1;
      
      public function GQXingZhiYuEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var yuyanResult:int;
         var key:String = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var raceId:int = int(thePet.raceId);
         var ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var isGQXingZhiYuPet:Boolean = Boolean(GQPetType.isXingZhiYu(ips.getOperationPM(raceId).pmData.getGQType()));
         key = KEY_STAND + "_" + locaId + "_" + "_gqXingZhiYueffect";
         var hasView:Boolean = layer.getChildByName(key) != null;
         if(!isGQXingZhiYuPet)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         if(_turn == FightController.instance.turnCount)
         {
            return;
         }
         yuyanResult = int(GQXingZhiYuSkillParse.getYuYanResult(thePet));
         if(hasView)
         {
            if(yuyanResult == -1)
            {
               layer.removeChild(layer.getChildByName(key));
               return;
            }
            if(yuyanResult == _lastYuYanResult)
            {
               layer.getChildByName(key).visible = isGQXingZhiYuPet;
               return;
            }
            layer.removeChild(layer.getChildByName(key));
         }
         _lastYuYanResult = yuyanResult;
         if(_lastYuYanResult != -1)
         {
            _turn = FightController.instance.turnCount;
            ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
            {
               var mc:MovieClip = param1;
               var domain:ApplicationDomain = param2;
               mc.x = x;
               mc.y = y;
               mc.name = key;
               mc.mouseEnabled = mc.mouseChildren = false;
               layer.addChild(mc);
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  if(Boolean(mc) && Boolean(mc.parent))
                  {
                     mc.addFrameScript(mc.totalFrames - 1,null);
                     _lastYuYanResult = -1;
                     layer.removeChild(layer.getChildByName(key));
                  }
               });
            },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND + yuyanResult,ResPriority.LOW));
         }
      }
   }
}

