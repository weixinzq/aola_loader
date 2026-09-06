package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class DeadZoneExploreEffectHelper
   {
      
      private static const FLA:String = "gqpet/deadzoneexplore/effect/deadzoneexploreeffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.deadzoneexplore.effect.DeadZoneExploreEffect";
      
      public function DeadZoneExploreEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var momentums:Array;
         var key:String = null;
         var mc:MovieClip = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var raceId:int = int(thePet.raceId);
         var ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var isInDeadZoneExplore:Boolean = StatusUtil.getIsDeadZoneExploreByPbi(thePet);
         var face:int = getFace(locaId);
         key = KEY_STAND + "_" + locaId + "_" + face + "_deadzoneexploreeffect";
         var hasView:Boolean = layer.getChildByName(key) != null;
         if(!isInDeadZoneExplore)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         momentums = StatusUtil.getDeadZoneExploreMomentumsByPbi(thePet);
         if(momentums.length <= 0)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         if(momentums.length > 0 && hasView)
         {
            layer.getChildByName(key).visible = true;
            mc = layer.getChildByName(key) as MovieClip;
            updateMomentum(mc,thePet);
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y - 250;
            param1.name = key;
            if(layer && layer.parent && Boolean(thePet))
            {
               updateMomentum(param1,thePet);
               layer.addChild(param1);
            }
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND,ResPriority.LOW));
      }
      
      private static function updateMomentum(param1:MovieClip, param2:PetBriefInfo) : void
      {
         var _loc3_:MovieClip = param1.getChildByName("mcMomentum") as MovieClip;
         var _loc4_:MovieClip = _loc3_.getChildByName("mcBottom") as MovieClip;
         var _loc5_:int = _loc4_.width - 10;
         var _loc6_:Array = StatusUtil.getDeadZoneExploreMomentumsByPbi(param2);
         var _loc7_:int = _loc5_ * _loc6_[1] / _loc6_[0];
         var _loc8_:MovieClip = _loc3_.getChildByName("mcDetailNum") as MovieClip;
         _loc8_.width = _loc7_;
         ActComHelper.setTxtValue(_loc3_,"txtMomentum",_loc6_[1] + "/" + _loc6_[0]);
      }
      
      private static function getFace(param1:int) : int
      {
         return FightData.instance.isMySide(param1) ? 2 : 1;
      }
   }
}

