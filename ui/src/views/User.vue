<template>
  <Card :title="$t(funcText[func])" class="user-mgr-container">
    <Form ref="User" :model="formData" :rules="ruleValidate" :label-width="100" label-position="left">
      <FormItem :label="$t('New Username')" prop="username" v-if="func == 2">
        <Input v-model="formData.username" prefix="ios-person-outline" :placeholder="$t('Enter username...')"
          @on-enter="handleSubmit" />
      </FormItem>
      <FormItem :label="$t('Username')" prop="username" v-if="func == 1 || func == 3">
        <Select v-model="formData.username" prefix="ios-person-outline" :placeholder="$t('Select username...')"
          @on-enter="handleSubmit">
          <Option v-for="user in users" :key="user" :value="user">{{ user }}</Option>
        </Select>
      </FormItem>
      <FormItem :label="$t('New Password')" prop="n_password" v-if="func != 3">
        <Input type="password" v-model="formData.n_password" prefix="ios-lock-outline"
          :placeholder="$t('Enter password...')" @on-enter="handleSubmit" />
      </FormItem>
      <FormItem :label="$t('Confirm New Password')" prop="c_password" v-if="func != 3">
        <Input type="password" v-model="formData.c_password" prefix="ios-lock-outline"
          :placeholder="$t('Enter password...')" @on-enter="handleSubmit" />
      </FormItem>
      <FormItem :label="$t('Set as Admin')" v-if="func == 2" prop="setadmin">
        <input type="checkbox" size="small" v-bind:checked="formData.setadmin" v-model="formData.setadmin" />
      </FormItem>
      <FormItem>
        <Button type="primary" style="margin-left: 10px;" size="small" @click="handleAdmin" v-if="func == 1">
          {{ $t(this.admins.includes(formData.username) ? 'Remove Admin' : 'Set as Admin') }}
        </Button>
        <Button type="primary" style="margin-left: 10px;" size="small" @click="handleSubmit">{{ $t(funcText[func])
          }}</Button>
        <Button type="primary" style="margin-left: 10px;" size="small" @click="handleCancel">{{ $t('Return') }}</Button>
      </FormItem>
    </Form>
    <Div v-if="isadmin">
      <!-- if is admin go to user management page -->
      <p v-if="func != 0" style="text-align: center"><a href="/User?func=0"
          style="text-decoration: none; color: #1c7cd6">{{ $t(funcText[0]) }}</a></p>
      <p v-if="func != 1" style="text-align: center"><a href="/User?func=1"
          style="text-decoration: none; color: #1c7cd6">{{ $t(funcText[1]) }}</a></p>
      <p v-if="func != 2" style="text-align: center"><a href="/User?func=2"
          style="text-decoration: none; color: #1c7cd6">{{ $t(funcText[2]) }}</a></p>
      <p v-if="func != 3" style="text-align: center"><a href="/User?func=3"
          style="text-decoration: none; color: #1c7cd6">{{ $t(funcText[3]) }}</a></p>
    </Div>

  </Card>
</template>

<script>
export default {
  name: 'User',
  data() {
    const validatePassword = (rule, value, callback) => {
      if (value !== this.formData.n_password) {
        callback(new Error(this.$t('Passwords do not match')));
      } else {
        callback();
      }
    };
    const validateUsername = (rule, value, callback) => {
      // if create user, check if username exists
      if (this.users.includes(value) && this.func === 2) {
        callback(new Error(this.$t('Username already exists')));
        return;
      } else if (value === this.login_username && (this.func === 2 || this.func === 3)) {
        callback(new Error(this.$t('Cannot create or delete user with the same username as the logged in user')));
        return;
      }
      callback();
    };
    return {
      func: 0,
      funcText: ['Change Password', 'Update User', 'Create User', 'Remove User'],
      users: [],
      admins: [],
      login_username: '',
      isadmin: false,
      formData: {
        username: '',
        setadmin: false,
        n_password: '',
        c_password: ''
      },
      ruleValidate: {
        username: [{ required: true, trigger: 'blur', message: this.$t('Please input the username') }, { validator: validateUsername }],
        n_password: [{ required: this.func !== 3, trigger: 'blur', message: this.$t('Please input the new password') }],
        c_password: [{ required: this.func !== 3, trigger: 'blur', message: this.$t('Please confirm the password') }, { validator: validatePassword }]
      }
    }
  },
  methods: {
    handleAdmin() {
      const params = {
        username: this.formData.username,
        setadmin: !this.admins.includes(this.formData.username),
        func: 1
      };
      this.axios.post('/User', params).then(() => {
        this.$Message.success(this.$t('Success!').toString());
        this.axios.get('/users').then(res => {
          this.users = res.data.users;
        });
        this.axios.get('/admins').then(res => {
          this.admins = res.data.admins;
        });
      }).catch((e) => {
        e.response.data.error ? this.$Message.error(this.$t(e.response.data.error).toString()) : this.$Message.error(this.$t('Fail!').toString());
      });
    },
    handleCancel() {
      if (this.func === 0) {
        this.$router.push('/');
        return;
      }
      this.$router.push('/User?func=0');
      this.func = 0;
    },
    handleSubmit() {
      (this.$refs['User']).validate(valid => {
        if (valid) {
          const params = {
            username: this.formData.username,
            setadmin: this.formData.setadmin,
            password: this.formData.c_password,
            func: this.func
          };
          this.axios.post('/User', params).then(() => {
            this.$Message.success(this.$t('Success!').toString());
            this.axios.get('/users').then(res => {
              this.users = res.data.users;
            });
            this.axios.get('/admins').then(res => {
              this.admins = res.data.admins;
            });
          }).catch((e) => {
            e.response.data.error ? this.$Message.error(this.$t(e.response.data.error).toString()) : this.$Message.error(this.$t('Fail!').toString());
          });
        }
      });
    }
  },
  created() {
    this.func = parseInt(this.$route.query.func) || 0;
    this.axios.get('/isadmin').then(res => {
      if (res.data.admin === true) {
        this.isadmin = true;
      } else {
        this.isadmin = false;
      }
    }).catch(() => {
      this.isadmin = false;
    });
    this.axios.get('/users').then(res => {
      this.users = res.data.users;
    });
    this.axios.get('/admins').then(res => {
      this.admins = res.data.admins;
    });
    this.login_username = sessionStorage.getItem('rttys-username') || '';
  },
  watch: {
    'formData.username'(newVal) {
      this.formData.setadmin = this.admins.includes(newVal);
    },
    'func'(newVal) {
      this.formData.username = '';
      this.formData.setadmin = false;
      this.formData.n_password = '';
      this.formData.c_password = '';
      this.func = parseInt(newVal) || 0;
    }
  }
}
</script>

<style scoped>
.user-mgr-container {
  width: 500px;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}
</style>
