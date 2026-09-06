package mmo.petfightnew.common.panel.state
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class StatusViewBase extends Sprite
   {
      
      public function StatusViewBase(param1:String, param2:String)
      {
         var url:String = param1;
         var className:String = param2;
         super();
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),className));
      }
   }
}

