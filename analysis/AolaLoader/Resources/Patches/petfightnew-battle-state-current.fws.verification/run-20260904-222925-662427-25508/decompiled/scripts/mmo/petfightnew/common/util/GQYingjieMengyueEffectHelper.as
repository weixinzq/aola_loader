package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class GQYingjieMengyueEffectHelper
   {
      
      private static const FLA:String = "gqpet/yingjiemengyue/effect/yingjiemengyueeffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.yingjiemengyue.effect.GQYingjieMengyueEffectMv";
      
      public function GQYingjieMengyueEffectHelper()
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
         key = KEY_STAND + "_" + locaId + "_" + "_yingjiemengyueeffect";
         var hasView:Boolean = layer.getChildByName(key) != null;
         var isInBuxiugonglingState:Boolean = StatusUtil.getIsInBuxiugonglingState(thePet);
         if(hasView)
         {
            if(!isInBuxiugonglingState)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            else
            {
               layer.getChildByName(key).visible = true;
            }
         }
         else if(isInBuxiugonglingState)
         {
            ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
            {
               param1.x = x;
               param1.y = y - 180;
               param1.name = key;
               layer.addChild(param1);
               param1.gotoAndPlay(1);
            },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND,ResPriority.LOW));
         }
      }
   }
}

