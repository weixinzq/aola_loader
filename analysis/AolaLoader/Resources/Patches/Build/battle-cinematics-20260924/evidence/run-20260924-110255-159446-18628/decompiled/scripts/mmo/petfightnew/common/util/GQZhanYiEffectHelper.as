package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQZhanYiSkillParse;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class GQZhanYiEffectHelper
   {
      
      private static const FLA:String = "gqpet/zhanyi/effect/zhanyieffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.zhanyi.effect.GQzhanyiEffectMv";
      
      public function GQZhanYiEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var key:String = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var raceId:int = int(thePet.raceId);
         var _zhanYiParser:GQZhanYiSkillParse = thePet.getGQZhanYiSkillParse();
         var hasState:Boolean = Boolean(_zhanYiParser.isBianShening());
         var ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var face:int = getFace(locaId);
         key = KEY_STAND + "_" + locaId + "_" + face + "_zhanyieffect";
         var hasView:Boolean = layer.getChildByName(key) != null;
         var isGQZhanYiPet:Boolean = Boolean(GQPetType.isZhanYi(ips.getOperationPM(raceId).pmData.getGQType()));
         if(hasState && hasView)
         {
            layer.getChildByName(key).visible = isGQZhanYiPet && raceId <= 10000;
            return;
         }
         if(raceId > 10000)
         {
            return;
         }
         if(!hasState && hasView)
         {
            layer.removeChild(layer.getChildByName(key));
            return;
         }
         if(!hasState)
         {
            return;
         }
         if(!isGQZhanYiPet)
         {
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y - 250;
            param1.name = key;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND,ResPriority.LOW));
      }
      
      private static function removeChild(param1:Sprite, param2:String) : *
      {
         if(param1.getChildByName(param2) != null)
         {
            param1.removeChild(param1.getChildByName(param2));
         }
      }
      
      private static function getFace(param1:int) : int
      {
         return FightData.instance.isMySide(param1) ? 2 : 1;
      }
   }
}

