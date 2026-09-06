package mmo.petfightnew.common
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.manager.FightMcFactory;
   import mmo.petfightnew.common.manager.FightMcKeys;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.useskill.ReallyDecHp;
   import mmo.petfightnew.common.useskill.ReallyShieldHit;
   import mmo.petfightnew.common.useskill.ShieldHitHp;
   import mmo.petfightnew.common.useskill.SkillResults;
   import mmo.petfightnew.common.useskill.StrongDecHp;
   
   public class SkillResultMovieHandler
   {
      
      public static const HPType_NormalHit:int = 0;
      
      public static const HPType_CriHit:int = 1;
      
      public static const HPType_ReallyHit:int = 2;
      
      public static const HPType_ShieldHit:int = 3;
      
      public static const HPType_ReallyShieldHit:int = 4;
      
      public static const HPType_Miss:int = 5;
      
      private var _hpInc:int;
      
      private var _movieContainer:DisplayObjectContainer = null;
      
      private var _moviePos:Point = null;
      
      private var _hpType:int = -1;
      
      private var _allReallyHit:int;
      
      public function SkillResultMovieHandler(param1:DisplayObjectContainer)
      {
         super();
         this._movieContainer = param1;
      }
      
      public function startMovie(param1:Boolean, param2:int, param3:int, param4:Boolean, param5:int, param6:Boolean, param7:Point, param8:int = -1, param9:int = 0) : void
      {
         this._hpInc = param2;
         this._moviePos = param7;
         this._hpType = param8;
         this._allReallyHit = param9;
         if(param1)
         {
            param3 = SkillResults.HIT;
         }
         if(param3 == SkillResults.HIT)
         {
            if(param1 && this._hpType == HPType_Miss)
            {
               this.showMultipleHit();
            }
            else if(param2 > 0)
            {
               this.showIncMovie();
            }
            else if(param2 < 0)
            {
               if(param1)
               {
                  this.showMultipleHit();
               }
               else if(param4)
               {
                  this.showCriticalHit();
               }
               else if(this._hpType == HPType_ReallyHit)
               {
                  this.showReallyHit();
               }
               else if(this._hpType == HPType_ShieldHit)
               {
                  this.showShieldHit();
               }
               else if(this._hpType == HPType_ReallyShieldHit)
               {
                  this.showReallyShieldHit();
               }
               else
               {
                  this.setNormalMovie(param6,param5);
               }
            }
         }
         else if(param3 == SkillResults.MISS)
         {
            this.playMissMovie();
         }
         else if(param3 == SkillResults.NO_EFFECT)
         {
            this.showNoEffect();
         }
         else if(param3 == SkillResults.STIFF)
         {
            this.dispose();
         }
         else if(param3 == SkillResults.ALL_HIT && param2 < 0)
         {
            this.playAllHitMovie();
         }
      }
      
      public function showMultipleHitTimesMovie(param1:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showMultipleHit() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      public function recycleMovie(param1:MovieClip, param2:String) : void
      {
         FightMcPool.instance.pushMcByKey(param2,param1);
      }
      
      private function showIncMovie() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showCriticalHit() : void
      {
         this.playMovie(FightMcKeys.McCriticalHit,this.playStrongMovie);
      }
      
      private function showReallyHit() : void
      {
         var mc:MovieClip;
         var movie:ReallyDecHp;
         if(DocPetFight.hideDamageNumbers)
         {
            return;
         }
         movie = null;
         mc = FightMcFactory.getFightMcByKey(FightMcKeys.McReallyHit);
         movie = mc as ReallyDecHp;
         movie.startMovie(-this._hpInc,function():void
         {
            recycleMovie(movie,FightMcKeys.McReallyHit);
         });
         this.addToStage(movie);
      }
      
      private function showShieldHit() : void
      {
         var mc:MovieClip;
         var movie:ShieldHitHp;
         if(DocPetFight.hideDamageNumbers)
         {
            return;
         }
         movie = null;
         mc = FightMcFactory.getFightMcByKey(FightMcKeys.McShieldHit);
         movie = mc as ShieldHitHp;
         movie.startMovie(-this._hpInc,function():void
         {
            recycleMovie(movie,FightMcKeys.McShieldHit);
         });
         this.addToStage(movie);
      }
      
      private function showReallyShieldHit() : void
      {
         var mc:MovieClip;
         var movie:ReallyShieldHit;
         if(DocPetFight.hideDamageNumbers)
         {
            return;
         }
         movie = null;
         mc = FightMcFactory.getFightMcByKey(FightMcKeys.McReallyShieldHit);
         movie = mc as ReallyShieldHit;
         movie.startMovie(-this._hpInc,function():void
         {
            recycleMovie(movie,FightMcKeys.McReallyShieldHit);
         });
         this.addToStage(movie);
      }
      
      private function playStrongMovie() : void
      {
         var movie:mmo.petfightnew.common.useskill.StrongDecHp;
         if(DocPetFight.hideDamageNumbers)
         {
            return;
         }
         movie = null;
         movie = FightMcFactory.getFightMcByKey(FightMcKeys.StrongDecHp) as mmo.petfightnew.common.useskill.StrongDecHp;
         movie.startMovie(-this._hpInc,function():void
         {
            recycleMovie(movie,FightMcKeys.StrongDecHp);
         });
         this.addToStage(movie);
      }
      
      private function setNormalMovie(param1:Boolean, param2:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function playAllHitMovie() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function dispose() : void
      {
      }
      
      private function playMissMovie() : void
      {
         this.playMovie(FightMcKeys.Miss);
      }
      
      private function showNoEffect() : void
      {
         this.playMovie(FightMcKeys.McNoEffect);
      }
      
      private function playMovie(param1:String, param2:Function = null) : void
      {
         var movie:MovieClip = null;
         var key:String = param1;
         var afterMovie:Function = param2;
         movie = FightMcFactory.getFightMcByKey(key);
         movie.gotoAndStop(1);
         FightMovieManager.instance.addMovie(movie);
         movie.addFrameScript(movie.totalFrames - 1,function():*
         {
            FightMovieManager.instance.removeMovie(movie);
            recycleMovie(movie,key);
            if(afterMovie != null)
            {
               afterMovie.apply();
            }
         });
         movie.gotoAndPlay(1);
         this.addToStage(movie);
      }
      
      private function addToStage(param1:MovieClip, param2:Boolean = false) : void
      {
         var _loc3_:Point = null;
         if(!param2)
         {
            param1.x = this._moviePos.x;
            param1.y = this._moviePos.y;
         }
         else
         {
            _loc3_ = this._movieContainer.globalToLocal(new Point(480,480));
            param1.x = _loc3_.x;
            param1.y = _loc3_.y;
         }
         this._movieContainer.addChild(param1);
         param1.addEventListener(Event.REMOVED,this.onMovieRemoved);
      }
      
      private function onMovieRemoved(param1:Event) : void
      {
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         _loc2_.removeEventListener(Event.REMOVED,this.onMovieRemoved);
         this.dispose();
      }
   }
}

