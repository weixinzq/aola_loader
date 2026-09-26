package mmo.petfightnew.common.component
{
   import avmplus.getQualifiedClassName;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   
   public class CachedClip extends Sprite
   {
      
      private var _source:MovieClip = null;
      
      private var _frameClipList:Array;
      
      private var _totalFrames:int = 0;
      
      private var _currentFrame:int = -1;
      
      private var _frameChildNum:Array;
      
      private var _curClip:Sprite;
      
      private var _cacheKey:String;
      
      public function CachedClip(param1:MovieClip)
      {
         var _loc3_:int = 0;
         this._frameClipList = [];
         this._frameChildNum = [];
         super();
         this.tabEnabled = this.tabChildren = false;
         this._source = param1;
         param1.tabChildren = param1.tabEnabled = false;
         this._cacheKey = getQualifiedClassName(param1) + "Cached";
         this._totalFrames = param1.totalFrames;
         var _loc2_:DisplayObjectContainer = this._source.parent;
         if(_loc2_)
         {
            _loc2_.tabChildren = _loc2_.tabEnabled = false;
            _loc3_ = _loc2_.getChildIndex(this._source);
            this.x = this._source.x;
            this.y = this._source.y;
            this.transform = this._source.transform;
            _loc2_.addChildAt(this,_loc3_);
            _loc2_.removeChild(this._source);
         }
         this.gotoAndStop(1);
      }
      
      public function gotoAndStop(param1:int) : void
      {
         if(param1 < 1)
         {
            param1 = 1;
         }
         else if(param1 > this._totalFrames)
         {
            param1 = this._totalFrames;
         }
         if(this._currentFrame == param1)
         {
            return;
         }
         this._currentFrame = param1;
         this.render();
      }
      
      private function render() : void
      {
         var _loc2_:Sprite = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc1_:int = this._currentFrame - 1;
         if(this._frameChildNum[_loc1_] <= 1)
         {
            if(this._curClip != null)
            {
               this.removeChild(this._curClip);
               this._curClip = null;
            }
            return;
         }
         if(this._frameClipList[_loc1_] == null)
         {
            this._source.gotoAndStop(this._currentFrame);
            _loc3_ = this._source.numChildren;
            this._frameChildNum[_loc1_] = _loc3_ + 1;
            if(_loc3_ > 0)
            {
               _loc2_ = new Sprite();
               _loc4_ = 0;
               while(_loc4_ < _loc3_)
               {
                  (_loc2_ as Sprite).addChild(this._source.getChildAt(0));
                  _loc4_++;
               }
            }
            this._frameClipList[_loc1_] = _loc2_;
         }
         else
         {
            _loc2_ = this._frameClipList[_loc1_];
         }
         if(this._curClip != _loc2_ || _loc3_ == 0)
         {
            if(this._curClip != null)
            {
               this.removeChild(this._curClip);
            }
            this._curClip = _loc2_;
            if(this._curClip)
            {
               this.addChild(this._curClip);
            }
         }
      }
      
      override public function getChildByName(param1:String) : DisplayObject
      {
         if(Boolean(this._curClip) && this._curClip is DisplayObjectContainer)
         {
            return (this._curClip as DisplayObjectContainer).getChildByName(param1);
         }
         return null;
      }
      
      override public function getChildAt(param1:int) : DisplayObject
      {
         if(Boolean(this._curClip) && this._curClip is DisplayObjectContainer)
         {
            return (this._curClip as DisplayObjectContainer).getChildAt(param1);
         }
         return null;
      }
      
      public function dispose() : void
      {
         this._source = null;
         this._frameChildNum.length = 0;
         this._frameChildNum = null;
         this._curClip = null;
         this._frameClipList.length = 0;
         this._frameClipList = null;
      }
      
      public function get cacheKey() : String
      {
         return this._cacheKey;
      }
      
      public function get curClip() : Sprite
      {
         return this._curClip;
      }
      
      override public function get numChildren() : int
      {
         if(this._frameChildNum == null)
         {
            return 0;
         }
         return Math.max(0,this._frameChildNum[this._currentFrame - 1] - 1);
      }
      
      public function get totalFrames() : int
      {
         return this._totalFrames;
      }
   }
}

