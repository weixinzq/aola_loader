package mmo.petfightnew.common.panel
{
   import flash.display.DisplayObject;
   import mmo.common.panel.PanelBase;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.play.activity.helper.StringUtil;
   
   public class GQMingYunBoYiChoosePanel extends PanelBase
   {
      
      private static const OrderNum:int = 4;
      
      private var _orders:Array = [];
      
      public function GQMingYunBoYiChoosePanel()
      {
         super("pet/petfightnew_gqresource","mmo.petfightnew.common.panel.view.GQMingYunBoYiChoosePanel");
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
      }
      
      override protected function addListeners() : void
      {
         super.addListeners();
         this.regClickFunc(/^btn[a-zA-Z0-9_]+/,this.onClickButton,true,null,this);
         FightEventDispatcher.instance.addEventListener(PetFightEvent.ON_COUNTDOWN,this.onCountDown);
      }
      
      private function onClickButton(param1:DisplayObject) : void
      {
         var _loc2_:String = param1.name;
         var _loc3_:int = int(this.intelligentlyGetIndex(param1));
         switch(_loc2_)
         {
            case "btnSelect":
               if(this._orders.indexOf(_loc3_) != -1)
               {
                  this._orders.splice(_loc3_,1);
               }
               else
               {
                  this._orders.push(_loc3_);
               }
               this.refreshPanel();
         }
      }
      
      override protected function refreshPanel(param1:Object = null) : void
      {
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         while(_loc2_ < OrderNum)
         {
            _loc3_ = int(this._orders.indexOf(_loc2_));
            if(_loc3_ > -1)
            {
               this.setVisible("mcOrder" + _loc2_,true);
               this.setFrame("mcOrder" + _loc2_,_loc3_ + 1);
               this.setFrame("mcSelect" + _loc2_,2);
            }
            else
            {
               this.setVisible("mcOrder" + _loc2_,false);
               this.setFrame("mcSelect" + _loc2_,1);
            }
            _loc2_++;
         }
         this.refreshObj("btnConfirm",this._orders.length < OrderNum);
      }
      
      override protected function onClickConfirm(param1:Object = null) : void
      {
         var _loc2_:String = StringUtil.initArrayToString(this._orders,":");
         super.onClickConfirm(_loc2_);
      }
      
      private function onCountDown(param1:PetFightEvent) : void
      {
         if(param1.params.leftSecond <= 0)
         {
            this.close();
         }
      }
      
      override public function dispose() : void
      {
         super.dispose();
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.ON_COUNTDOWN,this.onCountDown);
      }
   }
}

