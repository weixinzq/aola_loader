package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.XHFaHuanSkillParse;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class XingHuiFaHuanHelper
   {
      
      private static const FLA:String = "xinghuipet/fahuan/effect/xinghuifahuanatallmv";
      
      private static const CLS_EFFECT_0:String = "mmo.xinghuipet.fahuan.XingHuiFaHuanAtAllMv_0";
      
      private static const KEY_0:String = "xinghuifahuanatallmv_0";
      
      private static const CLS_EFFECT_1:String = "mmo.xinghuipet.fahuan.XingHuiFaHuanAtAllMv_1";
      
      private static const KEY_1:String = "xinghuifahuanatallmv_1";
      
      public function XingHuiFaHuanHelper()
      {
         super();
      }
      
      public static function setEffectStatus_0(param1:Sprite, param2:PetBriefInfo, param3:int, param4:int, param5:Number, param6:Number) : void
      {
         var KEY_0:String = null;
         var layer:Sprite = param1;
         var petInfo:PetBriefInfo = param2;
         var locaId:int = param3;
         var raceId:int = param4;
         var x:Number = param5;
         var y:Number = param6;
         var hasState:Boolean = XHFaHuanSkillParse.getLastSkillType(petInfo) == XHFaHuanSkillParse.UseSkillType_NoStar;
         var face:int = getFace(locaId);
         KEY_0 = KEY_0 + "_" + locaId + "_" + face;
         var hasView_0:Boolean = layer.getChildByName(KEY_0) != null;
         var pmService:IPMService = ServicePool.instance.getService(IPMService);
         var isFaHuan:Boolean = XinghuiPetType.FA_HUAN == pmService.customData.pmDataMap.getPM(raceId).getXinghuiType();
         if(hasView_0 && hasState)
         {
            layer.getChildByName(KEY_0).visible = isFaHuan;
            return;
         }
         if(!hasState && hasView_0)
         {
            layer.removeChild(layer.getChildByName(KEY_0));
            return;
         }
         if(!hasState)
         {
            return;
         }
         if(!isFaHuan)
         {
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y;
            param1.name = KEY_0;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS_EFFECT_0,ResPriority.LOW));
      }
      
      public static function setEffectStatus_1(param1:Sprite, param2:PetBriefInfo, param3:int, param4:int, param5:Number, param6:Number) : void
      {
         var KEY_1:String = null;
         var layer:Sprite = param1;
         var petInfo:PetBriefInfo = param2;
         var locaId:int = param3;
         var raceId:int = param4;
         var x:Number = param5;
         var y:Number = param6;
         var hasState:Boolean = XHFaHuanSkillParse.getLastSkillType(petInfo) == XHFaHuanSkillParse.UseSkillType_HasStar;
         var face:int = getFace(locaId);
         KEY_1 = KEY_1 + "_" + locaId + "_" + face;
         var hasView_1:Boolean = layer.getChildByName(KEY_1) != null;
         var pmService:IPMService = ServicePool.instance.getService(IPMService);
         var isFaHuan:Boolean = XinghuiPetType.FA_HUAN == pmService.customData.pmDataMap.getPM(raceId).getXinghuiType();
         if(hasView_1 && hasState)
         {
            layer.getChildByName(KEY_1).visible = isFaHuan;
            return;
         }
         if(!hasState && hasView_1)
         {
            layer.removeChild(layer.getChildByName(KEY_1));
            return;
         }
         if(!hasState)
         {
            return;
         }
         if(!isFaHuan)
         {
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y;
            param1.name = KEY_1;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS_EFFECT_1,ResPriority.LOW));
      }
      
      private static function getFace(param1:int) : int
      {
         return FightData.instance.isMySide(param1) ? 2 : 1;
      }
      
      private static function getReplacedStr(param1:String, param2:String) : String
      {
         return param1.replace("#",param2);
      }
   }
}

