package mmo.petfightnew.common.helper
{
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   
   public class LoadFileHelper
   {
      
      public function LoadFileHelper()
      {
         super();
      }
      
      public static function preloadSingleFile(param1:String, param2:ResDomain) : void
      {
         var url:String = param1;
         var domain:ResDomain = param2;
         ResScheduler.getRes(ResParams.create(url,null,domain,ResPriority.PRELOAD,null,function():*
         {
         }));
      }
   }
}

