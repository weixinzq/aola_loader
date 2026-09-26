package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQShenXuSkillParse;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class GQShenXuEffectHelper
   {
      
      private static const FLA:String = "gqpet/shenxu/effect/shenxueffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.shenxu.effect.GQShenxuEffectMv";
      
      public function GQShenXuEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var _shenXuSkillParser:GQShenXuSkillParse;
         var key:String = null;
         var strengthSkillLv:int = 0;
         var face:int = 0;
         var mc:MovieClip = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var raceId:int = int(thePet.raceId);
         var ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var isGQShenxuPet:Boolean = Boolean(GQPetType.isShenXu(ips.getOperationPM(raceId).pmData.getGQType()));
         key = KEY_STAND + "_" + locaId + "_" + face + "_gqshenxueffect";
         var hasView:Boolean = layer.getChildByName(key) != null;
         if(!isGQShenxuPet)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         if(raceId > 10000)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         _shenXuSkillParser = GQShenXuSkillParse.getGQShenXuSkillParse(thePet.raceId);
         strengthSkillLv = int(_shenXuSkillParser.getInStrengthSkillLv(thePet.skills));
         face = getFace(locaId);
         if(strengthSkillLv <= 0)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         if(strengthSkillLv > 0 && hasView)
         {
            layer.getChildByName(key).visible = isGQShenxuPet && raceId <= 10000;
            mc = layer.getChildByName(key) as MovieClip;
            mc.gotoAndStop(strengthSkillLv);
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y - 250;
            param1.name = key;
            param1.gotoAndStop(strengthSkillLv);
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND,ResPriority.LOW));
      }
      
      private static function getFace(param1:int) : int
      {
         return FightData.instance.isMySide(param1) ? 2 : 1;
      }
   }
}

