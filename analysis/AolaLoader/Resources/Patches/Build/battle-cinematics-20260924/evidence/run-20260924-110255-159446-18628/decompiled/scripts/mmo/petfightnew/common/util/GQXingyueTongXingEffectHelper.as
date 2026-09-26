package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQXingyueTongxingSkillParse;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class GQXingyueTongXingEffectHelper
   {
      
      private static const FLA:String = "gqpet/xingyuetongxing/effect/xingyuetongxingeffect_";
      
      private static const KEY_STAND:String = "gq_xytx_stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.xingyuetongxing.effect.GQXingyuetongxingStandEffectMv_#";
      
      public function GQXingyueTongXingEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var _xingyuetongxingSkillParser:GQXingyueTongxingSkillParse;
         var hasView:Boolean;
         var key:String = null;
         var extraSkillIndex:int = 0;
         var mc:MovieClip = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var raceId:int = int(PetAssetsMap.getPetFlaId(thePet.raceId));
         var ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var isGQXingyuetongxingPet:Boolean = Boolean(GQPetType.isXingyueTongxing(ips.getOperationPM(raceId).pmData.getGQType()));
         key = KEY_STAND + "_" + locaId + "#" + raceId + "#bird";
         var i:int = layer.numChildren - 1;
         while(i >= 0)
         {
            mc = layer.getChildAt(i) as MovieClip;
            if(mc)
            {
               if(mc.name.indexOf(KEY_STAND + "_" + locaId + "#") != -1 && parseInt(mc.name.split("#")[1]) != raceId)
               {
                  DisplayUtil.stopAndRemove(mc);
               }
            }
            i--;
         }
         if(!isGQXingyuetongxingPet)
         {
            return;
         }
         _xingyuetongxingSkillParser = GQXingyueTongxingSkillParse.getXingyueTongxingSkillParse(thePet.raceId);
         extraSkillIndex = int(_xingyuetongxingSkillParser.getExtraSkillIndex(thePet));
         hasView = layer.getChildByName(key) != null;
         if(extraSkillIndex >= 0 && hasView)
         {
            layer.getChildByName(key).visible = isGQXingyuetongxingPet && raceId <= 10000;
            mc = layer.getChildByName(key) as MovieClip;
            mc.gotoAndStop(extraSkillIndex + 1);
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y - 250;
            param1.name = key;
            param1.gotoAndStop(extraSkillIndex + 1);
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),getReplacedStr(CLS_STAND,raceId.toString()),ResPriority.LOW));
      }
      
      private static function getReplacedStr(param1:String, param2:String) : String
      {
         return param1.replace("#",param2);
      }
   }
}

