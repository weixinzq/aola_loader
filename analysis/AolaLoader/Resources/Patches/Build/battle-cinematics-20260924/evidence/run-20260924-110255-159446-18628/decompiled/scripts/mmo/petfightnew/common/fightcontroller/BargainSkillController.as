package mmo.petfightnew.common.fightcontroller
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.BargainPetConfig;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   
   public class BargainSkillController
   {
      
      public function BargainSkillController()
      {
         super();
      }
      
      public static function addBargainSkillIcon(param1:PetBriefInfo, param2:DisplayObjectContainer) : void
      {
         var raceId:int = 0;
         var pbi:PetBriefInfo = param1;
         var container:DisplayObjectContainer = param2;
         raceId = pbi.raceId % 10000;
         raceId = int(BargainPetConfig.getBargainIdByTargetId(raceId));
         if(raceId == -1)
         {
            return;
         }
         ResScheduler.getRes(ResParams.createTemp("pet/bargain/skillicon/icon" + raceId.toString(),function(param1:Sprite, param2:ApplicationDomain = null):void
         {
            container.addChild(param1);
            DisplayUtil.stop(param1);
            DisplayUtil.scaleDisplay(param1,25,25);
            DisplayUtil.middleDisplay(param1,25,25);
            param1.x += 775;
            param1.y += 90;
            TipsManager.getInstance().addComplexTips(param1,BargainPetConfig.getBargainSkillName(raceId),BargainPetConfig.getBargainSkillDetail(raceId,pbi.changeViewLevel));
         },"mmo.bargain.SkillIcon" + raceId.toString()));
      }
   }
}

