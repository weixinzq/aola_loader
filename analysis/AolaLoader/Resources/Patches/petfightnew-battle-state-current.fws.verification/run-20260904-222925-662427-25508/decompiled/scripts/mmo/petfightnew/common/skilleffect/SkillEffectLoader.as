package mmo.petfightnew.common.skilleffect
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.system.ApplicationDomain;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.helper.SkillEffectHelper;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.config.SkillMap;
   
   public class SkillEffectLoader extends EventDispatcher
   {
      
      private var _isDisposed:Boolean = false;
      
      private var _id:int;
      
      private var _onLoaded:Function;
      
      private var _domain:ApplicationDomain;
      
      public function SkillEffectLoader()
      {
         super();
         this._domain = FightData.instance.applicationDomain;
      }
      
      public static function loadObject(param1:ResourceObject, param2:Function) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      public function getEffect(param1:int, param2:Function) : void
      {
         if(this._isDisposed)
         {
            return;
         }
         this._id = param1;
         this._onLoaded = param2;
         if(SkillMap.instance.isBitmapSkillEffect(param1))
         {
            this.applyGot(SkillEffectHelper.getBitmapMovie(param1));
         }
         else
         {
            this.getVectorEffectMovie();
         }
      }
      
      private function getVectorEffectMovie() : void
      {
         var clsName:String;
         var cls:Class = null;
         var url:String = null;
         var cachedKey:String = SkillEffectHelper.getCacheKey(this._id);
         var mcEffect:MovieClip = FightMcPool.instance.getMcByKey(cachedKey);
         if(mcEffect != null)
         {
            this.applyGot(mcEffect);
            return;
         }
         clsName = FightResConfig.getVectorEffectMovieClsName(this._id);
         if(this._domain.hasDefinition(clsName))
         {
            cls = this._domain.getDefinition(clsName) as Class;
            mcEffect = new cls() as MovieClip;
            this.applyGot(mcEffect);
         }
         else
         {
            url = FightResConfig.getVectorEffectMovieURL(this._id);
            ResScheduler.getResource(url,this.applyGot,clsName,function():*
            {
               applyGot(null);
            },null,ResPriority.HIGHEST,false,this._domain);
         }
      }
      
      private function applyGot(param1:DisplayObject) : void
      {
         if(this._isDisposed)
         {
            return;
         }
         this._onLoaded.apply(null,[param1]);
      }
      
      public function dispose() : void
      {
         this._isDisposed = true;
      }
   }
}

