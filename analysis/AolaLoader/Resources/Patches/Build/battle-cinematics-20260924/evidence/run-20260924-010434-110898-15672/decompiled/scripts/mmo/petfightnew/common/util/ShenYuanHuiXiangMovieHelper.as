package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   
   public class ShenYuanHuiXiangMovieHelper
   {
      
      private static const FLA:String = "xinghuipet/shenyuanhuixiang/movie/shenyuanhuixiangmovie";
      
      private static const CLS:String = "mmo.petfight.shenyuanhuixiang.ShenYuanHuiXiangMovie";
      
      public function ShenYuanHuiXiangMovieHelper()
      {
         super();
      }
      
      public static function showEff(param1:Array, param2:Array, param3:Sprite) : void
      {
         var ids:Array = param1;
         var sourceId:Array = param2;
         var layer:Sprite = param3;
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            /*
             * Decompilation error
             * Code may be obfuscated
             * Tip: You can try enabling "Deobfuscate code" option in Settings
             * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
             */
            throw new flash.errors.IllegalOperationError("Not decompiled due to error");
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS));
      }
   }
}

