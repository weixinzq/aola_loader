package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class HunDunLiLiangEffectHelper
   {
      
      private static const FLA:String = "xinghuipet/hundunliliangeffect/hundunliliangeffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.petfight.hundunliliangeffect.PetStand";
      
      private static const buffStr:String = "hdxh_0";
      
      public function HunDunLiLiangEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:String, param4:int, param5:Number, param6:Number) : void
      {
         var ips:IPMService;
         var face:int;
         var hasView:Boolean;
         var isHundunPet:Boolean;
         var key:String = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var statusStr:String = param3;
         var raceId:int = param4;
         var x:Number = param5;
         var y:Number = param6;
         var hasState:Boolean = false;
         var statusList:Array = StatusUtil.parseStatusStr(statusStr);
         var i:int = 0;
         while(i < statusList.length)
         {
            if(statusList[i] == buffStr)
            {
               hasState = true;
               break;
            }
            i++;
         }
         ips = ServiceContainer.getService(IPMService) as IPMService;
         face = getFace(locaId);
         key = KEY_STAND + "_" + locaId + "_" + face + "_hundunliliangeffect";
         hasView = layer.getChildByName(key) != null;
         isHundunPet = XinghuiPetType.HUNDUN_XINGHUI == ips.customData.pmDataMap.getPM(raceId).getXinghuiType();
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
            DisplayUtil.stopAndRemove(layer.getChildByName(key));
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

