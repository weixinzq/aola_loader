package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   
   public class UIPanelBase extends MovieClip
   {
      
      private var _type:int;
      
      public function UIPanelBase()
      {
         super();
         this.tabChildren = false;
         this.tabEnabled = false;
      }
      
      public function setClickable(param1:Boolean) : void
      {
         this.mouseChildren = this.mouseEnabled = param1;
      }
      
      public function update() : void
      {
      }
      
      public function dispose() : void
      {
      }
      
      public function get type() : int
      {
         return this._type;
      }
      
      public function set type(param1:int) : void
      {
         this._type = param1;
      }
      
      public function setNoClickIntoHandle() : void
      {
      }
   }
}

