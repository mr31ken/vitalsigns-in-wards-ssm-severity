// 
functions {
  // 部分尤度を計算する関数
  real partial_sum_lpdf(array[] real slice_y, int start, int end, real mu, real sigma) {
    return normal_lpdf(slice_y | mu, sigma); // 正規分布の対数尤度
  }
}

data {
  int<lower=1> grainsize;
  
  int total_pts;// number of pts
  int total_obs;// number of obs
  int total_measure;// nubmer of total data
  int total_name;// nubmer of vital signs
  
  // int obs_is[total_obs];
  array[total_obs] int obs_is;
  // int obs_js[total_obs];
  array[total_obs] int obs_js;
  // int obs_ijs[total_obs];
  array[total_obs] int obs_ijs;
  
  vector[total_obs] obs_dts;
  
  
  // int mes_is[total_measure];
  array[total_measure] int mes_is;
  // int mes_ijs[total_measure];
  array[total_measure] int mes_ijs;
  // int mes_ks[total_measure];
  array[total_measure] int mes_ks;
  
  vector[total_measure] mes_values;
  vector[total_measure] mes_abn_values;
}

parameters {
  // vector<lower=0,upper=30>[total_pts] pts_base_is;
  array[total_pts] real <lower=0,upper=30> pts_base_is;
  
  // vector<lower=-100,upper=100>[total_obs] dmg_ijs_div;
  array[total_obs] real <lower=-100,upper=100> dmg_ijs_div;
  
  // real <lower=0>coef_dt;
  // real <lower=0>coef_dt_div;
  real <lower=0>coef_dt_div;
  // real <lower=0, upper=1e+6>coef_dt_div;
  
  // vector<lower=0,upper=50>[total_measure] mu_ijs;
  simplex [total_name]as0;
  // simplex [total_name]bs;
  // vector [total_name]cs;
  // vector [total_name]ds;
  
  // real<lower=0> sigma_ijs;
  // real<lower=0> sigma_ijss;
  real<lower=0, upper=10> sigma_ijs_ijss;
  
  // vector <lower=0>[total_name]sigma_links;
  // vector <lower=0>[total_name]sigma_ks;
  // vector <lower=0>[total_name]sigma_kks;
}

transformed parameters {
  // transformed parametersで実際の状態を得る
  vector[total_obs] dmg_ijs;

  
  vector<lower=0>[total_obs] sigma_dt;
  vector[total_measure] phi_ijs;
  
  // vector<lower=0>[total_measure] sigma_ijks;
  // vector<lower=0>[total_measure] sigma_ijkks;
  vector[total_measure] mes_phi_ijs;
  // real sigma_ijs_ijss_inv;
  // vector[total_measure] mes_mu_ijks;
  
  
  vector<lower=0> [total_name] as;
  
  // vector[total_obs + 2*total_measure] all_outs;
  
  array[total_obs] real dmg_ijs_div_a ;
  array[total_measure] real mes_phi_ijs_a;  

  as = total_name* as0;
  // sigma_ijs_ijss_inv = 1/sigma_ijs_ijss;
  for(s in 1:total_obs){
    if (obs_js[s] ==1){
        sigma_dt[s] = coef_dt_div * sqrt(1/(24 * 60));
        
        dmg_ijs[s] = pts_base_is[obs_is[s]] + dmg_ijs_div[s]*sigma_dt[s];
        
      }
    else{
        sigma_dt[s] = coef_dt_div * sqrt(obs_dts[s]);
        // sigma_dt[s] = coef_dt_div * obs_dts[s];
        
        dmg_ijs[s] = dmg_ijs[s -1] + dmg_ijs_div[s]*sigma_dt[s];
        
      }

  }
  phi_ijs = as[mes_ks] .* dmg_ijs[mes_ijs];
  // phi_ijs = total_name * as[mes_ks] .* dmg_ijs[mes_ijs];
  // sigma_ijks  = sigma_ks[mes_ks];
  mes_phi_ijs = (mes_abn_values - phi_ijs);
  
  dmg_ijs_div_a = to_array_1d(dmg_ijs_div);
  mes_phi_ijs_a = to_array_1d(mes_phi_ijs);
  
}

model {
  // dmg_ijs_div ~ normal(0,1);
  // mes_phi_ijs ~ normal(0,sigma_ijs_ijss);
  // 
  target += reduce_sum(partial_sum_lpdf, dmg_ijs_div_a, grainsize, 0.0, 1.0);
  target += reduce_sum(partial_sum_lpdf, mes_phi_ijs_a, grainsize, 0.0, sigma_ijs_ijss);
  
}



