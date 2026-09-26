package mmo.petpackage.controller.helper
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   
   public class BargainSkillIconHelper
   {
      
      public function BargainSkillIconHelper()
      {
         super();
      }
      
      public static function loadIcon(param1:int, param2:DisplayObjectContainer, param3:Number, param4:Number) : void
      {
         var bargainPetRaceId:int = param1;
         var container:DisplayObjectContainer = param2;
         var width:Number = param3;
         var height:Number = param4;
         ResScheduler.getRes(ResParams.createTemp("pet/bargain/skillicon/icon" + bargainPetRaceId.toString(),function(param1:Sprite, param2:ApplicationDomain = null):void
         {
            container.addChild(param1);
            DisplayUtil.stop(param1);
            DisplayUtil.scaleDisplay(param1,width - 5,height - 5);
            DisplayUtil.middleDisplay(param1,width,height);
         },"mmo.bargain.SkillIcon" + bargainPetRaceId.toString()));
      }
   }
}

