package mmo.petfightnew.common.panel.hp
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class NewHPBar
   {
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _mcHP:MovieClip;
      
      private var _isLeftStart:Boolean;
      
      private var _GQShieldWidth:Number;
      
      private var _barWidth:Number;
      
      private var _mcBlood:Sprite;
      
      private var _mcShield:Sprite;
      
      private var _txtHp:TextField;
      
      private var _txtPercentHp:TextField;
      
      private var _haveShieldTips:Boolean = false;
      
      private var _isFightInfo:Boolean = false;
      
      private var _txtYirenShield:TextField;
      
      private var _mcGQAllShield:Sprite;
      
      private var _mcGQShield:MovieClip;
      
      private var _mcGQReallyShield:MovieClip;
      
      private var _mcGQStrongShield:MovieClip;
      
      private var _isGQYiren:Boolean;
      
      private var _isTouzhiHp:Boolean;
      
      private var _mcReallyHp:MovieClip;
      
      private var _mcGuiLingXieYiHp:MovieClip;
      
      public function NewHPBar(param1:MovieClip, param2:Boolean, param3:Boolean = false, param4:Boolean = false)
      {
         super();
         this._isLeftStart = param2;
         this._haveShieldTips = param3;
         this._mcHP = param1;
         this._isGQYiren = false;
         this._isTouzhiHp = false;
         this._isFightInfo = param4;
         this._mcGQAllShield = ActComHelper.getChildNode(this._mcHP,"mcGQAllShield") as Sprite;
         var _loc5_:Sprite = ActComHelper.getChildNode(this._mcGQAllShield,"mcGQShield.mcBottom") as Sprite;
         this._GQShieldWidth = _loc5_.width - 3;
         this._mcGQShield = ActComHelper.getChildNode(this._mcGQAllShield,"mcGQShield") as MovieClip;
         this._mcGQShield.mouseChildren = false;
         this._mcGQReallyShield = ActComHelper.getChildNode(this._mcGQAllShield,"mcGQReallyShield") as MovieClip;
         this._mcGQReallyShield.mouseChildren = false;
         this._mcGQStrongShield = ActComHelper.getChildNode(this._mcGQAllShield,"mcGQStrongShield") as MovieClip;
         this._mcGQStrongShield.mouseChildren = false;
         if(this._isLeftStart && !this._isFightInfo)
         {
            this._mcGuiLingXieYiHp = ActComHelper.getChildNode(this._mcHP,"mcGuiLingXieYiHp") as MovieClip;
            this._mcGuiLingXieYiHp.mouseChildren = false;
         }
         this.update(null);
      }
      
      public function update(param1:PetBriefInfo) : void
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc14_:int = 0;
         var _loc15_:int = 0;
         var _loc16_:int = 0;
         var _loc17_:Object = null;
         var _loc18_:int = 0;
         var _loc19_:Object = null;
         var _loc20_:MovieClip = null;
         var _loc21_:MovieClip = null;
         var _loc22_:MovieClip = null;
         var _loc23_:MovieClip = null;
         var _loc24_:Array = null;
         var _loc25_:Sprite = null;
         var _loc26_:int = 0;
         if(param1)
         {
            _loc5_ = StatusUtil.getCurrHp(param1);
            _loc6_ = int(param1.maxHp);
            _loc7_ = int(param1.currentShield);
            _loc8_ = int(param1.maxShield);
            _loc9_ = int(param1.currGQShield);
            _loc10_ = int(param1.maxGQShield);
            _loc11_ = int(param1.currGQReallyShield);
            _loc12_ = int(param1.maxGQReallyShield);
            _loc13_ = int(param1.currGQStrongShield);
            _loc14_ = int(param1.maxGQStrongShield);
            _loc15_ = int(StatusUtil.getYirenShieldByPbi(param1)[0]);
            _loc16_ = int(StatusUtil.getYirenShieldByPbi(param1)[1]);
            this._isGQYiren = GQPetType.isYiRen(this._pmSvr.getOperationPM(param1.raceId).pmData.getGQType());
            this._isTouzhiHp = StatusUtil.getIsTouzhiHpByPbi(param1);
         }
         else
         {
            _loc5_ = 0;
            _loc6_ = 1;
            _loc7_ = 0;
            _loc8_ = 0;
            _loc9_ = 0;
            _loc10_ = 0;
            _loc11_ = 0;
            _loc12_ = 0;
            _loc13_ = 0;
            _loc14_ = 0;
            _loc15_ = 0;
            _loc16_ = 0;
         }
         var _loc2_:MovieClip = this._mcHP.mcYirenHP;
         var _loc3_:MovieClip = this._mcHP.mcTouzhiHp;
         var _loc4_:MovieClip = this._mcHP.mcMiBaoHp;
         (_loc4_) && (_loc4_.visible = false);
         this._mcHP.mcHp.visible = true;
         this._mcReallyHp = null;
         if(Boolean(param1) && StatusUtil.getIsAtMiBaoStrollState(param1))
         {
            if(_loc4_)
            {
               _loc17_ = GQPetType.getMiBaoObject(param1.raceId);
               _loc18_ = _loc17_ == null ? 1 : int(_loc17_["iconFrame"]);
               _loc4_.gotoAndStop(_loc18_);
               _loc4_.visible = true;
               ActComHelper.setTxtValue(_loc4_,"txtMiBao",param1.curGQSoulNum + "/99");
            }
            _loc2_ && (_loc2_.visible = false);
            _loc3_ && (_loc3_.visible = false);
            this._mcHP.mcHp.visible = false;
            ActComHelper.setTxtValue(this._mcHP,"txtHpRadio",param1.curGQSoulNum + "");
         }
         else if(this._isGQYiren && Boolean(_loc2_))
         {
            DisplayUtil.stop(this._mcHP.mcHp);
            this._mcHP.mcHp.visible = false;
            if(_loc3_)
            {
               DisplayUtil.stop(this._mcHP.mcTouzhiHp);
               this._mcHP.mcTouzhiHp.visible = false;
            }
            this._mcReallyHp = this._mcHP.mcYirenHP;
            _loc19_ = GQPetType.getYiRenObject(PetAssetsMap.getPetFlaId(param1.viewId));
            if((Boolean(_loc19_)) && !this._isLeftStart)
            {
               this._mcReallyHp.gotoAndStop(_loc19_.hpBarBgFrame);
            }
            else
            {
               this._mcReallyHp.gotoAndStop(1);
            }
         }
         else if(this._isTouzhiHp && Boolean(_loc3_))
         {
            DisplayUtil.stop(this._mcHP.mcHp);
            this._mcHP.mcHp.visible = false;
            if(_loc2_)
            {
               DisplayUtil.stop(this._mcHP.mcYirenHP);
               this._mcHP.mcYirenHP.visible = false;
            }
            this._mcReallyHp = this._mcHP.mcTouzhiHp;
         }
         else
         {
            if(_loc2_)
            {
               DisplayUtil.stop(this._mcHP.mcYirenHP);
               this._mcHP.mcYirenHP.visible = false;
            }
            if(_loc3_)
            {
               DisplayUtil.stop(this._mcHP.mcTouzhiHp);
               this._mcHP.mcTouzhiHp.visible = false;
            }
            this._mcReallyHp = this._mcHP.mcHp;
         }
         if(this._mcReallyHp)
         {
            this._mcReallyHp.visible = true;
         }
         if(_loc10_ <= 0 && _loc12_ <= 0 && _loc14_ <= 0)
         {
            this._mcGQAllShield.visible = false;
         }
         else
         {
            this._mcGQAllShield.visible = true;
            _loc20_ = this._mcGQShield.getChildByName("mc") as MovieClip;
            if(_loc10_ > 0)
            {
               this._mcGQShield.visible = true;
               _loc20_.width = _loc9_ * 1 * this._GQShieldWidth / _loc10_;
            }
            else
            {
               this._mcGQShield.visible = false;
            }
            TipsManager.getInstance().replaceTips(this._mcGQShield,_loc9_ + "/" + _loc10_);
            _loc21_ = this._mcGQReallyShield.getChildByName("mc") as MovieClip;
            if(_loc12_ > 0)
            {
               this._mcGQReallyShield.visible = true;
               _loc21_.width = _loc11_ * 1 * this._GQShieldWidth / _loc12_;
            }
            else
            {
               this._mcGQReallyShield.visible = false;
            }
            TipsManager.getInstance().replaceTips(this._mcGQReallyShield,_loc11_ + "/" + _loc12_);
            _loc22_ = this._mcGQStrongShield.getChildByName("mc") as MovieClip;
            if(_loc14_ > 0)
            {
               this._mcGQStrongShield.visible = true;
               _loc22_.width = _loc13_ * 1 * this._GQShieldWidth / _loc14_;
            }
            else
            {
               this._mcGQStrongShield.visible = false;
            }
            TipsManager.getInstance().replaceTips(this._mcGQStrongShield,_loc13_ + "/" + _loc14_);
            if(this._isLeftStart)
            {
               _loc20_.x = 1.3;
               _loc21_.x = 1.3;
               _loc22_.x = 1.3;
            }
            else
            {
               _loc20_.x = this._GQShieldWidth - _loc20_.width;
               _loc21_.x = this._GQShieldWidth - _loc21_.width;
               _loc22_.x = this._GQShieldWidth - _loc22_.width;
            }
         }
         if(this._isLeftStart && !this._isFightInfo && param1 && StatusUtil.getIsInGuiLingXieYiProgState(param1))
         {
            this._mcGuiLingXieYiHp.visible = true;
            _loc23_ = this._mcGuiLingXieYiHp.getChildByName("mc") as MovieClip;
            _loc24_ = StatusUtil.getGuiLingXieYiHpArr(param1);
            _loc23_.width = _loc24_[0] * 1 * this._GQShieldWidth / _loc24_[1];
            TipsManager.getInstance().replaceTips(this._mcGuiLingXieYiHp,_loc24_[0] + "/" + _loc24_[1]);
         }
         else if(Boolean(this._mcGuiLingXieYiHp) && Boolean(this._mcGuiLingXieYiHp.parent))
         {
            this._mcGuiLingXieYiHp.visible = false;
         }
         if(this._mcReallyHp)
         {
            this._mcBlood = this._mcReallyHp.getChildByName("mcBlood") as Sprite;
            this._mcShield = this._mcReallyHp.getChildByName("mcShield") as Sprite;
            this._txtHp = this._mcReallyHp.getChildByName("txtHp") as TextField;
            if(this._txtHp != null)
            {
               this._txtHp.selectable = false;
            }
            this._txtPercentHp = this._mcReallyHp.getChildByName("txtPercentHp") as TextField;
            if(this._txtPercentHp != null)
            {
               this._txtPercentHp.selectable = false;
            }
            _loc25_ = this._mcReallyHp.getChildByName("mcBottom") as Sprite;
            _loc26_ = _loc6_ + _loc8_;
            this._barWidth = _loc25_.width - 7;
            if(this._isGQYiren)
            {
               if(this._isLeftStart)
               {
                  this._mcBlood.width = (_loc5_ + _loc7_) * 1 * this._barWidth / _loc26_;
                  this._mcShield.width = _loc15_ * 1 * this._barWidth / _loc16_;
                  this._mcBlood.x = 5;
                  this._mcShield.x = 5;
               }
               else
               {
                  this._barWidth = _loc25_.width - 58;
                  this._mcBlood.width = (_loc5_ + _loc7_) * 1 * this._barWidth / _loc26_;
                  this._mcShield.width = _loc15_ * 1 * this._barWidth / _loc16_;
                  this._mcShield.x = this._barWidth - this._mcShield.width + 42.85;
                  this._mcBlood.x = this._barWidth - this._mcBlood.width + 42.85;
               }
            }
            else if(this._isTouzhiHp)
            {
               if(this._isLeftStart)
               {
                  this._mcBlood.width = StatusUtil.getTouzhiHpByPbi(param1) * 1 * this._barWidth / _loc26_;
                  this._mcBlood.x = 3.3;
               }
               else
               {
                  this._barWidth = _loc25_.width - 40;
                  this._mcBlood.width = StatusUtil.getTouzhiHpByPbi(param1) * 1 * this._barWidth / _loc26_;
                  this._mcBlood.x = this._barWidth - this._mcBlood.width;
               }
            }
            else if(this._isLeftStart)
            {
               this._mcBlood.width = _loc5_ * 1 * this._barWidth / _loc26_;
               this._mcShield.width = _loc7_ * 1 * this._barWidth / _loc26_;
               this._mcBlood.x = 3.3;
               this._mcShield.x = this._mcBlood.width;
            }
            else
            {
               this._barWidth = _loc25_.width - 40;
               this._mcBlood.width = _loc5_ * 1 * this._barWidth / _loc26_;
               this._mcShield.width = _loc7_ * 1 * this._barWidth / _loc26_;
               this._mcShield.x = this._barWidth - this._mcShield.width - this._mcBlood.width;
               this._mcBlood.x = this._barWidth - this._mcBlood.width;
            }
            if(this._txtHp)
            {
               if(this._isTouzhiHp)
               {
                  this._txtHp.text = "-" + StatusUtil.getTouzhiHpByPbi(param1) + "/" + _loc26_;
               }
               else
               {
                  this._txtHp.text = _loc5_ + _loc7_ + "/" + _loc26_;
               }
            }
            if(this._txtYirenShield)
            {
               this._txtYirenShield.text = _loc15_ + "/" + _loc16_;
            }
            if(this._txtPercentHp)
            {
               if(this._isTouzhiHp)
               {
                  this._txtPercentHp.text = "-" + Math.ceil(StatusUtil.getTouzhiHpByPbi(param1) / _loc26_ * 100) + "%";
               }
               else
               {
                  this._txtPercentHp.text = Math.ceil((_loc5_ + _loc7_) / _loc26_ * 100) + "%";
               }
            }
            if(param1 && param1.isShielded() && this._haveShieldTips)
            {
               TipsManager.getInstance().replaceTips(this._mcReallyHp,"护盾:" + _loc7_ + "/" + _loc8_);
            }
            else if(this._isGQYiren)
            {
               TipsManager.getInstance().replaceTips(this._mcReallyHp,"不朽者体力:" + _loc15_ + "/" + _loc16_);
            }
            else
            {
               TipsManager.getInstance().removeTips(this._mcReallyHp);
            }
         }
      }
   }
}

