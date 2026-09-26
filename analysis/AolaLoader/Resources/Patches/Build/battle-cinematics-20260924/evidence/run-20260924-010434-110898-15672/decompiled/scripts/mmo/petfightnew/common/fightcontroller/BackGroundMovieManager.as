package mmo.petfightnew.common.fightcontroller
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightMovieManager;
   
   public class BackGroundMovieManager
   {
      
      public function BackGroundMovieManager()
      {
         super();
      }
      
      public function playMC(param1:String, param2:DisplayObjectContainer) : void
      {
         var bs:String = param1;
         var container:DisplayObjectContainer = param2;
         var bsArr:Array = ["4","5","6","131"];
         if(bsArr.indexOf(bs) == -1)
         {
            return;
         }
         ResScheduler.getResource("backgroundmovie/backgroundmovie" + bs,function(param1:MovieClip):void
         {
            var mc:MovieClip = param1;
            FightMovieManager.instance.addMovie(mc);
            mc.addFrameScript(mc.totalFrames - 1,function():void
            {
               FightMovieManager.instance.removeMovie(mc);
               mc.stop();
               DisplayUtil.stopAndRemove(mc);
            });
            container.addChild(mc);
            mc.gotoAndPlay(1);
         },"BackGroundEffectMovie" + bs,null,null,ResPriority.NORMAL,true,FightData.instance.applicationDomain);
      }
   }
}

