package mmo.petfightnew.common.panel.skill.big
{
   public class BigSkillMCHandler_Default extends BigSkillMCHandler
   {
      
      public function BigSkillMCHandler_Default()
      {
         super();
      }
      
      override public function update() : void
      {
         super.update();
         this._mcChangeView.gotoAndStop(this._mcChangeView.totalFrames);
      }
      
      override protected function care() : Boolean
      {
         return true;
      }
   }
}

