package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   import mmo.interfaces.restraint.RestraintEffect;
   import mmo.petfightnew.common.component.CachedClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2321")]
   public class NormalDecHp extends HpChangeMovie
   {
      
      public var hp:MovieClip;
      
      private var _skillEffect:int;
      
      private var _isSuperEffect:Boolean;
      
      private var _mcEffect:CachedClip;
      
      private var _effectFrame:int;
      
      public function NormalDecHp()
      {
         super();
      }
      
      override protected function init() : void
      {
         super.init();
         var _loc1_:MovieClip = this.getChildByName("hp") as MovieClip;
         var _loc2_:MovieClip = _loc1_.getChildByName("mc") as MovieClip;
         this._mcEffect = new CachedClip(_loc2_);
      }
      
      public function setParam(param1:int, param2:Boolean) : NormalDecHp
      {
         this._skillEffect = param1;
         this._isSuperEffect = param2;
         return this;
      }
      
      override protected function initView() : void
      {
         this._numMcStartFrame = this._skillEffect == 1 ? 11 : 1;
         this.gotoAndStop(1);
         this.setEffect();
         this.setNums();
         this.startPlay();
      }
      
      private function setEffect() : void
      {
         this._effectFrame = 5;
         if(this._skillEffect == RestraintEffect.SUPER_EFFECT)
         {
            this._effectFrame = 4;
         }
         else if(this._skillEffect == RestraintEffect.STRONG_EFFECT)
         {
            if(this._isSuperEffect)
            {
               this._effectFrame = 3;
            }
            else
            {
               this._effectFrame = 1;
            }
         }
         else if(this._skillEffect == RestraintEffect.WEAK_EFFECT)
         {
            this._effectFrame = 2;
         }
         this._mcEffect.gotoAndStop(this._effectFrame);
      }
   }
}

