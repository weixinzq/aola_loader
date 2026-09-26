package mmo.petfightnew.common.manager
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import flash.utils.getQualifiedClassName;
   import mmo.common.bitmapmovie.BitmapMovieClip;
   import mmo.interfaces.IDispose;
   
   public class FightMcPool implements IDispose
   {
      
      private static var _instance:FightMcPool;
      
      private var _isDispose:Boolean;
      
      private var _domain:ApplicationDomain;
      
      private var map:Object = {};
      
      public function FightMcPool()
      {
         super();
      }
      
      public static function get instance() : FightMcPool
      {
         if(_instance == null)
         {
            _instance = new FightMcPool();
         }
         return _instance;
      }
      
      public static function removeMc(param1:MovieClip) : void
      {
         if(param1)
         {
            param1.stop();
         }
         if(Boolean(param1) && Boolean(param1.parent))
         {
            param1.parent.removeChild(param1);
         }
      }
      
      public function init(param1:ApplicationDomain) : void
      {
         this._domain = param1;
         this._isDispose = false;
      }
      
      public function getRes(param1:*, param2:Boolean) : *
      {
         var _loc4_:DisplayObject = null;
         var _loc5_:Array = null;
         var _loc6_:Class = null;
         var _loc3_:String = this.getClsName(param1);
         if(this.map.hasOwnProperty(_loc3_))
         {
            _loc5_ = this.map[_loc3_];
            if(_loc5_.length > 0)
            {
               _loc4_ = _loc5_.pop();
            }
         }
         if(_loc4_ == null && param2)
         {
            _loc6_ = this._domain.getDefinition(_loc3_) as Class;
            _loc4_ = new _loc6_();
         }
         return _loc4_;
      }
      
      public function recycle(param1:DisplayObject, param2:* = null) : void
      {
         var _loc3_:Array = null;
         if(param2 == null)
         {
            param2 = getQualifiedClassName(param1);
         }
         else
         {
            param2 = this.getClsName(param2);
         }
         if(param1 is DisplayObject && param1.parent != null)
         {
            param1.parent.removeChild(param1);
         }
         if(param1 is MovieClip)
         {
            (param1 as MovieClip).stop();
         }
         if(this.map.hasOwnProperty(param2))
         {
            _loc3_ = this.map[param2];
            _loc3_.push(param1);
         }
         else if(!this._isDispose)
         {
            this.map[param2] = [param1];
         }
      }
      
      private function getClsName(param1:*) : String
      {
         var _loc2_:String = null;
         if(param1 is Class)
         {
            _loc2_ = getQualifiedClassName(param1);
         }
         else
         {
            _loc2_ = param1;
         }
         return _loc2_;
      }
      
      public function getMcByKey(param1:String) : *
      {
         return this.getRes(param1,false) as MovieClip;
      }
      
      public function pushMcByKey(param1:String, param2:DisplayObject) : void
      {
         this.recycle(param2,param1);
      }
      
      public function dispose() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:* = undefined;
         var _loc3_:Array = null;
         var _loc4_:DisplayObject = null;
         if(this.map == null)
         {
            _instance = null;
            this._isDispose = true;
            return;
         }
         for(_loc1_ in this.map)
         {
            _loc2_ = this.map[_loc1_];
            if(_loc2_ is Array)
            {
               _loc3_ = _loc2_ as Array;
               for each(_loc4_ in _loc3_)
               {
                  this.disposeInstance(_loc4_);
               }
               _loc3_.length = 0;
            }
            else if(_loc2_ is DisplayObject)
            {
               this.disposeInstance(_loc2_ as DisplayObject);
            }
            delete this.map[_loc1_];
         }
         this.map = null;
         _instance = null;
         this._isDispose = true;
      }
      
      private function disposeInstance(param1:DisplayObject) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(param1 is BitmapMovieClip)
         {
            (param1 as BitmapMovieClip).dispose();
         }
         else
         {
            if(param1 is MovieClip)
            {
               (param1 as MovieClip).stop();
            }
            if(param1.parent != null)
            {
               param1.parent.removeChild(param1);
            }
         }
      }
   }
}

