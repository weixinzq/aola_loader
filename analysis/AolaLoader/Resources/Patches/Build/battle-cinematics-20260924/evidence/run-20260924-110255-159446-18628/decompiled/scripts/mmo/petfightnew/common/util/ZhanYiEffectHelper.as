package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.XingHuiZhanYiSkillParser;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class ZhanYiEffectHelper
   {
      
      private static const FLA:String = "xinghuipet/zhanyi/effect/zhanyieffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.petfight.zhanyi.effect.PetStand";
      
      private static const buffStr:String = "hdxh_0";
      
      public function ZhanYiEffectHelper()
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
         var _xingHuiZhanYiParser:XingHuiZhanYiSkillParser = thePet.getXingHuiZhanYiSkillParser();
         var hasState:Boolean = Boolean(_xingHuiZhanYiParser.isBianShening());
         var ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var face:int = getFace(locaId);
         key = KEY_STAND + "_" + locaId + "_" + face + "_zhanyieffect";
         var hasView:Boolean = layer.getChildByName(key) != null;
         var isHundunPet:Boolean = XinghuiPetType.ZHAN_YI == ips.customData.pmDataMap.getPM(raceId).getXinghuiType();
         if(hasState && hasView)
         {
            layer.getChildByName(key).visible = isHundunPet && raceId <= 10000;
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
         if(!isHundunPet)
         {
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y;
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

