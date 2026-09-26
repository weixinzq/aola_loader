package mmo.petpackage.controller.helper
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   
   public class AddPetDetailInfoHelper
   {
      
      public function AddPetDetailInfoHelper()
      {
         super();
      }
      
      public static function addDetailInfoMC(param1:int, param2:DisplayObjectContainer, param3:Function) : void
      {
         var type:int = param1;
         var container:DisplayObjectContainer = param2;
         var callback:Function = param3;
         ResScheduler.getRes(ResParams.createTemp("pet/petitem",function(param1:*, param2:ApplicationDomain):void
         {
            var _loc3_:* = param2.getDefinition("mmo.pet.petitem.PetItemPanel") as Class;
            var _loc4_:* = new _loc3_(type) as MovieClip;
            container.addChild(_loc4_);
            if(callback != null)
            {
               callback.apply();
            }
         },""));
      }
   }
}

